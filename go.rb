require 'pathname'
require 'fileutils'
require 'ostruct'
require 'optparse'

# Defaults
settings = OpenStruct.new
settings.number_of_cases_to_montecarlo = 200
GAMS_WORKING_FOLDER =  "GAMS_WrkTIMES"
MONTE_CARLO_FILE = "possible_scenarios.tsv"
RESULTS_FOLDER = "results"
LIST_OF_CASES_FILE = "cases.tsv"
RUN_FILE_TEMPLATE =  File.join(File.dirname(__FILE__),'run-file-template.erb')
NUMBER_OF_THREADS = 3
RUN_FILE_PREFIX = File.basename(LIST_OF_CASES_FILE, ".*")
TIMES_SOURCE_FOLDER =  "GAMS_SRCTIMESV380"
GAMS_SAVE_FOLDER =  "GamsSave"
VT_GAMS =  "VT_GAMS.CMD"
TIMES_2_VEDA = "times2veda.vdd"

veda_fe_folder = Pathname.getwd.parent
prefix = RUN_FILE_PREFIX 
times_source_folder = veda_fe_folder + TIMES_SOURCE_FOLDER
gams_working_folder =  veda_fe_folder + GAMS_WORKING_FOLDER
gdx_save_folder = gams_working_folder + GAMS_SAVE_FOLDER
vt_gams = times_source_folder + VT_GAMS
times_2_veda =times_source_folder + "times2veda.vdd"

# Command line options
OptionParser.new do |opts|

  opts.on("-n", "--number-to-montecarlo N", Integer, "Generate N cases from the possible scenarios file. If zero, will leave the current set untouched.") do |number|
    settings.number_of_cases_to_montecarlo = number
  end

  opts.on("-r", "--results-only", "Skip all the steps except for generating the results file") do
    settings.results_only = true
  end

  opts.on_tail("--version", "Show version") do
    puts IO.readlines(File.join(File.dirname(__FILE__), "CHANGES.md")).join
    exit
  end
end.parse!

# First we check if we are in the correct spot
unless Pathname.getwd.basename.to_s =~ /#{Regexp.escape(GAMS_WORKING_FOLDER)}/i
  puts "This script needs to be run from within the GAMS working folder."
  puts "This is usally C:\VEDA\VEDA_FE\GAMS_WrkTIMES"
  exit
end

unless settings.results_only
  # FIXME: Only do this if needed
  # Create the emissions constraint files
  require_relative 'dd-file-generators/create-emissions-constraint-dd-files'
  puts "Creating territorial emissions constraint files"
  create_ghg_constraint_files = CreateGHGConstraintFiles.new('.')
  create_ghg_constraint_files.go!

  require_relative 'dd-file-generators/create-non-traded-constraints'
  puts "Creating traded/non-traded emissions constraint files"
  create_ghg_constraint_files = CreateNonTradedSectorConstraints.new('.')
  create_ghg_constraint_files.go!

  # If the user has set the number of cases to generate to zero, then skip this stage
  unless settings.number_of_cases_to_generate == 0
    # Now we check if we have a source file for monte-carlo
    unless File.exists?(MONTE_CARLO_FILE)
      puts "Can't find a list of all the possible scenarios."
      puts "I'm going to copy one here from the git repository"
      puts FileUtils.copy(File.join(File.dirname(__FILE__),"possible_scenarios.tsv"), ".",  :verbose => true)
      if File.exists?(MONTE_CARLO_FILE)
        puts "Copied"
      else
        puts "Failed"
        exit
      end
    end

    # Now we can create the list of cases
    # FIXME: Only do this if MONTE_CARLO_FILE changed
    require_relative 'lib/create-list-of-cases'
    create_list_of_cases = CreateListOfCases.new
    create_list_of_cases.name_of_list_of_cases = LIST_OF_CASES_FILE
    create_list_of_cases.number_of_cases_to_generate = settings.number_of_cases_to_montecarlo
    create_list_of_cases.file_containing_possible_combinations_of_scenarios = MONTE_CARLO_FILE
    create_list_of_cases.print_intent
    create_list_of_cases.run!

    if create_list_of_cases.missing_scenario_files.length > 0
      puts "There are scenario files missing:"
      puts
      puts create_list_of_cases.missing_scenario_files
      puts
  
      puts "If the spelling is right in possible_scenarios.tsv then you probably need to get VEDA to produce them"

      puts <<-END

      1. Open VEDA_FE
      2. Select Basic Functions > Case Manager
      3. In the scenarios list, select all the possible scenarios you might want to use (you could just click All at the bottom)
      4. Check the box 'Create DD only'
      5. Click Solve and wait

      Then re-run this script
      END
    end
  end

  # Now we can create the run files
  # FIXME: Only do this if the list of cases has changed
  require_relative 'lib/create-run-files'

  create_run_files = CreateRunFiles.new

  # Set our defaults
  create_run_files.destination_folder_for_run_files  =  '.'
  create_run_files.name_of_file_containing_cases = LIST_OF_CASES_FILE
  create_run_files.name_of_run_file_template = RUN_FILE_TEMPLATE
  create_run_files.run

  if create_run_files.missing_scenario_files.length > 0
    puts "There are scenario files missing:"
    puts
    puts create_run_files.missing_scenario_files.keys
    puts

    puts "If the spelling is right in possible_scenarios.tsv then you probably need to get VEDA to produce them"

    puts <<-END

    1. Open VEDA_FE
    2. Select Basic Functions > Case Manager
    3. In the scenarios list, select all the possible scenarios you might want to use (you could just click All at the bottom)
    4. Check the box 'Create DD only'
    5. Click Solve and wait

    Then re-run this script
    END
    exit
  end

  # Now we run the files
  # FIXME: Refactor this and run-cases.rb

  unless File.exist?(times_source_folder)
    puts "Can't find TIMES source folder: #{times_source_folder}"
    exit
  end

  unless File.exist?(gams_working_folder)
    puts "Can't find GAMS working folder: #{gams_working_folder}"
    exit
  end

  unless File.exist?(gdx_save_folder)
    puts "Can't find GDX save folder: #{gdx_save_folder}"
    exit
  end

  unless File.exist?(vt_gams)
    puts "Can't find VT_GAMS script: #{vt_gams}"
    exit
  end

  unless File.exist?(times_2_veda)
    puts "Can't find times2veda.vdd script: #{times_2_veda}"
    exit
  end

  number_per_thread = (settings.number_of_cases_to_montecarlo/NUMBER_OF_THREADS).ceil # Ceil in case not precisely divisable

  threads = Array.new([NUMBER_OF_THREADS,settings.number_of_cases_to_montecarlo].min).map.with_index do |_,thread_number|
    Thread.new do
      start_number = (thread_number * number_per_thread)+1
      end_number = start_number + number_per_thread

      puts "Thread #{thread_number} doing case #{start_number} to case #{end_number}"
      i = start_number

      loop do
        case_name = "#{prefix}#{i}"
        puts "Looking for #{case_name}.RUN"
        unless File.exist?("#{case_name}.RUN")
        puts "Can't find #{File.expand_path("#{case_name}.RUN")}"
        puts "Halting"
        exit
        end
        puts "Executing #{case_name}"
        `#{vt_gams} #{case_name} GAMS_SRCTIMESV380 #{File.join(gdx_save_folder, case_name).gsub('/','\\')}`

        # FIXME: Check that the file was written

        puts "Putting #{case_name} into VEDA"
        `GDX2VEDA #{File.join(gdx_save_folder, case_name)} #{times_2_veda} #{case_name} > #{case_name}`
        i = i + 1
        if end_number && (i > end_number)
        puts "Done case #{end_number}"
        puts "Halting"
        break
        end
      end
      Thread::exit
    end
  end

  require 'thwait'
  ThreadsWait.all_waits(*threads) do |t|
  	puts "Thread #{t} has finished"
  end
end

# Now we are ready to write some results
unless File.exist?(RESULTS_FOLDER)
  puts "Creating a results folder: #{File.expand_path(RESULTS_FOLDER)}"
  Pathname.new(RESULTS_FOLDER).mkpath
end

puts "Creating cost-emissions charts"
require_relative 'costs-against-emissions/lib/write_cost_and_emissions_data'

writer = WriteCostAndEmissionsData.new
writer.file_names = [LIST_OF_CASES_FILE].concat(Dir[File.join(gdx_save_folder, "#{prefix}*.gdx")])
writer.data_directory = RESULTS_FOLDER
writer.run

puts "Creating build rate charts"
require_relative 'build-rates/lib/write_build_rates'
writer = WriteBuildRates.new
writer.file_names =  Dir[File.join(gdx_save_folder, "#{prefix}*.gdx")]
writer.data_directory = RESULTS_FOLDER
writer.run

puts "Creating flying brick charts"
require_relative 'flying-bricks/lib/write_detailed_costs'

writer = WriteDetailedCosts.new
writer.file_names = Dir[File.join(gdx_save_folder, "#{prefix}*.gdx")]
writer.data_directory = RESULTS_FOLDER
writer.run

puts "You can now view the results by running:"
puts "ruby -run -e httpd results -p 8000"
puts "And then opening your webbrowser at http://localhost:8000/cost-emissions-scatter.html"
