require 'pathname'
require 'fileutils'
require 'ostruct'
require 'optparse'
require 'thwait'
require 'logger'

require_relative 'lib/monte_carlo_sensitivities'
require_relative 'lib/create_run_files'
require_relative 'lib/list_of_cases'
require_relative 'lib/run_optimisation'
require_relative 'lib/extract_results'

class BatchRun

  attr_accessor :settings
  attr_accessor :names_of_all_the_cases

  def initialize
    initialize_variables
    set_defaults
  end

  def initialize_variables
    @settings = OpenStruct.new
    @names_of_all_the_cases = []
  end

  def set_defaults
    settings.number_of_cases_to_montecarlo = 2000
    settings.gams_working_folder =  "GAMS_WrkTIMES"
    settings.monte_carlo_file = "possible_scenarios.tsv"
    settings.results_folder = "results"
    settings.list_of_cases_files = ["cases.tsv"]
    settings.run_file_template =  File.join(File.dirname(__FILE__),'run-file-template.erb')
    settings.number_of_cases_to_optimize_simultaneously = 3
    settings.times_source_folder =  "GAMS_SRCTIMESV380"
    settings.gams_save_folder =  "GamsSave"
    settings.times_2_veda = "times2veda.vdd"
    settings.do_not_recalculate_if_gdx_exists = false
    settings.log = Logger.new(STDOUT)
  end

  def run
    check_we_are_in_the_right_spot
    copy_dd_files_to_gams_working_directory
    check_for_lists_of_cases_and_create_by_monte_carlo_if_needed
    create_run_files
    load_list_of_all_the_cases
    truncate_list_of_cases
    run_cases
    tell_the_user_how_to_view_results
  end

  def run_results_only
    load_list_of_all_the_cases
    write_results_in_parallel
    tell_the_user_how_to_view_results
  end
  
  def check_we_are_in_the_right_spot
    return if Pathname.getwd.basename.to_s =~ /#{Regexp.escape(settings.gams_working_folder)}/i
    log.fatal "This script needs to be run from within the GAMS working folder."
    log.fatal "This is usally C:\VEDA\VEDA_FE\GAMS_WrkTIMES"
    exit
  end

  def copy_dd_files_to_gams_working_directory
    log.warn "Copying scenario files accross"
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
    log.warn "Can't find a list of all the possible scenarios #{settings.monte_carlo_file}"
    log.warn "I'm going to copy one here from the git repository"
    log.info FileUtils.copy(File.join(File.dirname(__FILE__),"possible_scenarios.tsv"), settings.monte_carlo_file,  :verbose => true)
    unless File.exists?(settings.monte_carlo_file)
      log.fatal "Failed"
      exit
    end
    log.info "Copied"
  end

  def create_list_of_cases_using_montecarlo(list_of_cases_file)
    log.warn "Can't find #{list_of_cases_file} so I'm going to generate it using the monte-carlo-sensitivities routine"
    monte_carlo = MonteCarloSensitivities.new
    monte_carlo.name_of_list_of_cases = list_of_cases_file
    monte_carlo.number_of_cases_to_generate = settings.number_of_cases_to_montecarlo
    monte_carlo.file_containing_possible_combinations_of_scenarios = settings.monte_carlo_file
    monte_carlo.run!
    monte_carlo.print_intent
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

  def warn_about_missing_scenarios(missing_scenario_files)
    return unless missing_scenario_files.length > 0
    message =<<-END

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
    log.fatal message
  end

  def load_list_of_all_the_cases
    settings.list_of_cases_files.each do |list_of_cases_file|
      load_cases_from(list_of_cases_file)
    end
  end

  def truncate_list_of_cases
    return unless settings.only_run_the_first_n_cases
    @names_of_all_the_cases = @names_of_all_the_cases.first(settings.only_run_the_first_n_cases)
  end

  def load_cases_from(list_of_cases_file)
    list_of_cases = ListOfCases.new
    list_of_cases.load(list_of_cases_file)
    @names_of_all_the_cases.concat(list_of_cases.case_names)
  end


  def gdx_ok?(case_name)
    output_gdx_name = File.join(gdx_save_folder, case_name)+".gdx"
    Gdx.new(output_gdx_name).valid?
  end

  def run_cases
    cases_to_run = Queue.new
    run_optimsiation = RunOptimisation.new(settings)
    run_optimsiation.check_files_needed_to_run_times_are_available!

    extract_results = ExtractResults.new(settings)
    
    names_of_all_the_cases.each do |case_name|
      cases_to_run.push(case_name)
    end

    threads = Array.new(number_of_threads).map.with_index do |_,thread_number|
      Thread.new do
        loop do
          case_name = cases_to_run.pop(true) # True means don't block
          if should_run?(case_name)
            gdx_file = run_optimsiation.run_case(case_name)
            run_shell_command_to_extract_results(gdx_file)
          end
        end
      end
    end

    ThreadsWait.all_waits(*threads) do |t|
      log.info "Thread #{t} has finished"
    end
  end

  def should_run?(case_name)
    return true unless settings.do_not_recalculate_if_gdx_exists
    return false if gdx_ok?(case_name)
    true
  end

  def run_shell_command_to_extract_results(gdx_name)
    return unless gdx_name
    log.info `ruby #{File.expand_path(File.join(File.dirname(__FILE__), "update-result-from-gdx.rb"))} #{settings.results_folder} #{gdx_name}`
  end

  def write_results_in_parallel
    cases_to_run = Queue.new

    names_of_all_the_cases.each do |case_name|
      cases_to_run.push(case_name)
    end

    threads = Array.new(number_of_threads).map do
      Thread.new do
        loop do
          case_name = cases_to_run.pop(true) # True means don't block
          gdx_name = File.join(gdx_save_folder, "#{case_name}.gdx")
          run_shell_command_to_extract_results(gdx_name) if Gdx.new(gdx_name).valid? 
       end
      end
    end

    ThreadsWait.all_waits(*threads) do |t|
      log.info "Thread #{t} has finished"
    end
  end
  
  def gdx_save_folder
    Pathname.getwd.parent + settings.gams_working_folder + settings.gams_save_folder
  end

  def tell_the_user_how_to_view_results
    log.info "You can now view the results by running:"
    log.info "ruby -run -e httpd #{settings.results_folder} -p 8000"
    log.info "And then opening your web browser at http://localhost:8000/"
  end

  def number_of_threads
    # min so that don't have more threads than cases to run
    [settings.number_of_cases_to_optimize_simultaneously,names_of_all_the_cases.length].min
  end

  def log
    settings.log
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

    opts.on("-s", "--skip-existing", "Skip optimisation for cases where a gdx file exists") do
      settings.do_not_recalculate_if_gdx_exists = true
    end

    opts.on("--results-folder [folder]", "The folder in which to write the results (default results)") do |folder|
      settings.results_folder = folder
    end

    opts.on("--log-to-file [logfile.log]", "This logs the major events in the processing to a file rather than printing them onscreen") do |logfile|
      settings.log = Logger.new(logfile)
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
