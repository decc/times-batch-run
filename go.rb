require 'pathname'
require 'fileutils'
require 'ostruct'
require 'optparse'
require 'thwait'

require_relative 'lib/monte_carlo'
require_relative 'lib/create_run_files'
require_relative 'lib/list_of_cases'
require_relative 'lib/extract_overall_cost_and_emissions'
require_relative 'lib/extract_build_rates'
require_relative 'lib/extract_detailed_costs'
require_relative 'lib/write_detailed_emissions'

class BatchRun

  attr_accessor :settings

  def initialize
    set_defaults
  end

  def set_defaults
    @settings = OpenStruct.new
    settings.number_of_cases_to_montecarlo = 200
    settings.gams_working_folder =  "GAMS_WrkTIMES"
    settings.monte_carlo_file = "possible_scenarios.tsv"
    settings.results_folder = "results"
    settings.list_of_cases_files = ["cases.tsv"]
    settings.run_file_template =  File.join(File.dirname(__FILE__),'run-file-template.erb')
    settings.number_of_cases_to_optimize_simultaneously = 3
    settings.times_source_folder =  "GAMS_SRCTIMESV380"
    settings.gams_save_folder =  "GamsSave"
    settings.vt_gams =  "VT_GAMS.CMD"
    settings.times_2_veda = "times2veda.vdd"
  end

  def run
    check_we_are_in_the_right_spot
    copy_dd_files_to_gams_working_directory
    check_for_lists_of_cases_and_create_by_monte_carlo_if_needed
    create_run_files
    check_files_needed_to_run_times_are_available
    run_cases
    write_results
    tell_the_user_how_to_view_results
  end

  def run_results_only
    find_existing_gdx_files
    write_results
    tell_the_user_how_to_view_results
  end
  
  def find_existing_gdx_files
    @names_of_all_the_cases_that_solved = names_of_all_the_cases.select {|case_name| gdx_ok?(case_name)}
    puts "Found existing solutions for #{names_of_all_the_cases_that_solved.length} of the #{names_of_all_the_cases.length} cases in #{settings.list_of_cases_files.join(" ")}"
  end

  def check_we_are_in_the_right_spot
    return if Pathname.getwd.basename.to_s =~ /#{Regexp.escape(settings.gams_working_folder)}/i
    puts "This script needs to be run from within the GAMS working folder."
    puts "This is usally C:\VEDA\VEDA_FE\GAMS_WrkTIMES"
    exit
  end

  def copy_dd_files_to_gams_working_directory
    puts "Copying scenario files accross"
    FileUtils.cp(Dir[File.join(File.dirname(__FILE__), "dd-files", "*.dd")], ".", verbose: true)
  end

  def check_for_lists_of_cases_and_create_by_monte_carlo_if_needed
    settings.list_of_cases_files.each do |list_of_cases_file|
      next if File.exists?(list_of_cases_file)
      copy_possible_scenarios_file_if_needed
      create_list_of_cases_using_montecarlo(list_of_cases_file)
    end
  end

  def copy_possible_scenarios_file_if_needed
    return if File.exists?(settings.monte_carlo_file)
    puts "Can't find a list of all the possible scenarios #{settings.monte_carlo_file}"
    puts "I'm going to copy one here from the git repository"
    puts FileUtils.copy(File.join(File.dirname(__FILE__),"possible_scenarios.tsv"), settings.monte_carlo_file,  :verbose => true)
    unless File.exists?(settings.monte_carlo_file)
      puts "Failed"
      exit
    end
    puts "Copied"
  end

  def create_list_of_cases_using_montecarlo(list_of_cases_file)
    puts "Can't find #{list_of_cases_file} so I'm going to generate it using the monte-carlo routine"
    monte_carlo = MonteCarlo.new
    monte_carlo.name_of_list_of_cases = list_of_cases_file
    monte_carlo.number_of_cases_to_generate = settings.number_of_cases_to_montecarlo
    monte_carlo.file_containing_possible_combinations_of_scenarios = settings.monte_carlo_file
    monte_carlo.print_intent
    monte_carlo.run!

    warn_about_missing_scenarios(monte_carlo.missing_scenario_files)
  end

  def warn_about_missing_scenarios(missing_scenario_files)
    return unless missing_scenario_files.length > 0
    puts <<-END

    There are scenario files missing:

    #{missing_scenario_files}

    If the spelling is right in possible_scenarios.tsv then you probably need to get VEDA to produce them

    1. Open VEDA_FE
    2. Select Basic Functions > Case Manager
    3. In the scenarios list, select all the possible scenarios you might want to use (you could just click All at the bottom)
    4. Check the box 'Create DD only'
    5. Click Solve and wait

    Then re-run this script
    END
  end

  def create_run_files
    settings.list_of_cases_files.each do |list_of_cases_file|
      create_run_files_for_list_of_cases(list_of_cases_file)
    end
  end

  def create_run_files_for_list_of_cases(list_of_cases_file)
    create_run_files = CreateRunFiles.new

    # Set our defaults
    create_run_files.destination_folder_for_run_files  =  '.'
    create_run_files.name_of_file_containing_cases = list_of_cases_file
    create_run_files.name_of_run_file_template = settings.run_file_template
    create_run_files.run

    warn_about_missing_scenarios(create_run_files.missing_scenario_files.keys)
    exit if create_run_files.missing_scenario_files.length > 0
  end

  def names_of_all_the_cases
    return @names_of_all_the_cases if @names_of_all_the_cases
    @names_of_all_the_cases = []
    settings.list_of_cases_files.each do |list_of_cases_file|
      load_cases_from(list_of_cases_file)
    end
    # We can limit ourselves to processing only a few cases like this
    if settings.only_run_the_first_n_cases
      @names_of_all_the_cases = @names_of_all_the_cases.first(settings.only_run_the_first_n_cases)
    end
    @names_of_all_the_cases
  end

  def load_cases_from(list_of_cases_file)
    list_of_cases = ListOfCases.new
    list_of_cases.load(list_of_cases_file)
    @names_of_all_the_cases.concat(list_of_cases.case_names)
  end

  def names_of_all_the_cases_that_solved
    @names_of_all_the_cases_that_solved ||= []
  end

  def check_files_needed_to_run_times_are_available

    files_to_check = {
      TIMES_source_folder: times_source_folder,
      GAMS_working_folder: path_to_gams_working_folder,
      GDX_save_folder: gdx_save_folder,
      VT_GAMS_script: vt_gams,
      times2veda_script: times_2_veda
    }

    files_to_check.each do |name, location|
      next if File.exist?(location)
      puts "Can't find #{name.to_s.gsub('_',' ')} at #{File.expand_path(location)}"
      exit
    end
  end

  def number_of_threads
    # min so that don't have more threads than cases to run
    [settings.number_of_cases_to_optimize_simultaneously,names_of_all_the_cases.length].min
  end

  def number_of_cases_per_thread
    # Ceil in case not precisely divisable
    (settings.number_of_cases_to_montecarlo/names_of_all_the_cases.length).ceil
  end

  def run_case(case_name)
    puts "Looking for #{case_name}.RUN"
    unless File.exist?("#{case_name}.RUN")
      puts "Can't find #{File.expand_path("#{case_name}.RUN")}"
      puts "Halting"
      exit
    end
    puts "Executing #{case_name}"
    output_gdx_name = File.join(gdx_save_folder, case_name)

    `#{vt_gams} #{case_name} #{settings.times_source_folder} #{output_gdx_name.gsub('/','\\')}`

    if gdx_ok?(case_name)
      names_of_all_the_cases_that_solved.push(case_name)
      puts "Putting #{case_name} into VEDA"
      `GDX2VEDA #{output_gdx_name.gsub('/','\\')} #{times_2_veda} #{case_name} > #{case_name}`
      puts "Updating the results"
      write_results(["#{output_gdx_name}.gdx"])
    else
      puts "Case #{case_name} failed to solve - couldn't find valid #{output_gdx_name}.gdx"
    end
  end

  def gdx_ok?(case_name)
    output_gdx_name = File.join(gdx_save_folder, case_name)
    File.exist?(output_gdx_name+".gdx") && Gdx.new(output_gdx_name+".gdx").valid?
  end

  def run_cases
    cases_to_run = names_of_all_the_cases.dup
    lock = Mutex.new
    threads = Array.new(number_of_threads).map.with_index do |_,thread_number|
      Thread.new do
        loop do
          case_name = nil
          lock.synchronize {
            break if cases_to_run.empty?
            case_name = cases_to_run.pop
          }
          break unless case_name # Shouldn't be needed
          run_case(case_name)
        end
        Thread::exit
      end
    end

    ThreadsWait.all_waits(*threads) do |t|
      puts "Thread #{t} has finished"
    end
  end

  def list_of_gdx_files
    names_of_all_the_cases_that_solved.map { |case_name| File.join(gdx_save_folder, "#{case_name}.gdx") }
  end

  def write_results(gdx_files = list_of_gdx_files)
    # Now we are ready to write some results
    unless File.exist?(settings.results_folder)
      puts "Creating a results folder: #{File.expand_path(settings.results_folder)}"
      Pathname.new(settings.results_folder).mkpath
    end

    puts "Copying accross html"
    FileUtils.cp_r(Dir.glob(File.join(File.dirname(__FILE__),"results-template",'*')),settings.results_folder)

    gdx_files.each do |gdx_file_name|
      puts "Writing results for #{gdx_file_name}"

      gdx = Gdx.new(gdx_file_name)
      name = File.basename(gdx_file_name, '.*')

      Pathname.new(File.join(settings.results_folder, name)).mkpath

      puts "Creating cost-emissions scatter"
      extract_and_write_result name, gdx, ExtractOverallCostAndEmissions.new, "costs-and-emissions-overview.json"
      
      puts "Creating build rate charts"
      extract_and_write_result name, gdx, ExtractBuildRates.new, "build-rates.json"

      puts "Creating flying brick cost charts"
      extract_and_write_result name, gdx, ExtractDetailedCosts.new, "detailed-costs.json"
    end

    puts "Creating flying brick emissions charts"
    writer = WriteDetailedEmissions.new
    writer.file_names = gdx_files
    writer.data_directory = settings.results_folder
    writer.run

    puts "Creating the index"
    write_index_txt
  end

  def extract_and_write_result(name, gdx, extractor, filename)
    extractor.gdx = gdx
    extractor.scenario_name = name
    results = extractor.extract_results
    write_result name, filename, results.to_json
  end

  def write_result(case_name, result, data)
    File.open(File.join(settings.results_folder, case_name, result), 'w') do |f|
      f.puts data
    end
  end

  # This ensures that index.txt in the results folder has ALL the results
  # not just those produced in this run
  def write_index_txt
    # Case directories are the ones with json in them
    case_directories = Dir[File.join(settings.results_folder,'*/*.json')].map { |f| File.basename(File.dirname(f)) }.uniq
    File.open(File.join(settings.results_folder, "index.txt"), 'w') { |f| f.puts case_directories.join("\n") }
  end

  def veda_fe_folder
    Pathname.getwd.parent
  end

  def times_source_folder
    veda_fe_folder + settings.times_source_folder
  end

  def path_to_gams_working_folder
    veda_fe_folder + settings.gams_working_folder
  end

  def gdx_save_folder
    path_to_gams_working_folder + settings.gams_save_folder
  end

  def vt_gams
    times_source_folder + settings.vt_gams
  end

  def times_2_veda
    times_source_folder + "times2veda.vdd"
  end

  def tell_the_user_how_to_view_results
    puts "You can now view the results by running:"
    puts "ruby -run -e httpd #{settings.results_folder} -p 8000"
    puts "And then opening your webbrowser at http://localhost:8000/cost-emissions-scatter.html"
  end

end

if __FILE__ == $0
  batch_run = BatchRun.new
  settings = batch_run.settings

  # Command line options
  OptionParser.new do |opts|

    opts.banner = "Usage: #{File.basename(__FILE__)} [options] [cases.tsv] [cases2.tsv]"

    opts.on("-n", "--number-of-cases-to-run N", Integer, "Only runs the first N cases") do |n|
      settings.only_run_the_first_n_cases = n
    end

    opts.on("--number-to-montecarlo N", Integer, "Generate N cases from the possible scenarios file. Only gets used if the list of cases is missing.") do |number|
      settings.number_of_cases_to_montecarlo = number
    end

    opts.on("-p", "--cases-in-parallel N", Integer, "Try and optimize N cases at the same time (in parallel).") do |number|
      settings.number_of_cases_to_optimize_simultaneously = number
    end

    opts.on("-r", "--results-only", "Skip all the steps except for generating the results file") do
      settings.results_only = true
    end

    opts.on("--results-folder [folder]", "The folder in which to write the results (default results)") do |folder|
      settings.results_folder = folder
    end

    opts.on_tail("--version", "Show version") do
      puts IO.readlines(File.join(File.dirname(__FILE__), "CHANGES.md")).join
      exit
    end
  end.parse!

  unless ARGV.empty?
    settings.list_of_cases_files = ARGV
  end

  if settings.results_only 
    batch_run.run_results_only
  else
    batch_run.run
  end
end
