require 'erb'
require 'ostruct'

require_relative 'scenario_file_methods'
require_relative 'list_of_cases'

class CreateRunFiles
  include ScenarioFileMethods

  attr_accessor :destination_folder_for_run_files
  attr_accessor :name_of_file_containing_cases
  attr_accessor :places_to_look_for_scenario_files
  attr_accessor :missing_scenario_files
  attr_reader   :list_of_cases
  attr_reader   :headers
  attr_accessor :settings

  def initialize(settings = OpenStruct.new)
    @settings = settings
    @missing_scenario_files = {}
  end

  def run
    load_list_of_cases

    list_of_cases.each do |c|

      log.info "Generating #{run_filename(c.first)}"

      list_of_dd_files = []
      list_of_scenarios = []

      c.each.with_index do |scenario, column_number|
        next if column_number == 0 # Skip the name of the case

        # Can supply scenarios in the form: name space <arguments>
        scenario_parts = scenario.split(/\s+/)
        scenario_name = scenario_parts.first
        scenario_arguments = scenario_parts[1..-1]

        if nil_scenario_file?(scenario_name)
          list_of_scenarios << "default_#{headers[column_number]}"
          next
        end

        list_of_scenarios << scenario.gsub(' ', '_').gsub('.', '_')

        unless scenario_file_exists?(scenario_name)
          missing_scenario_files[scenario_name] = true
        end

        list_of_dd_files << "$BATINCLUDE #{scenario_filename_from_name(scenario_name)} #{scenario_arguments.join(" ")}" 
      end

      list_of_dd_files = list_of_dd_files.join("\n")

      File.open(run_filename(c.first), 'w') do |f|
        f.puts run_file_template.result(binding)
      end
    end
  end

  def run_filename(case_name)
    File.expand_path(File.join(destination_folder_for_run_files, "#{case_name}.RUN"))
  end

  def load_list_of_cases
    file = ListOfCases.new
    file.load(name_of_file_containing_cases)
    @headers = file.header
    @list_of_cases = file.tsv
  end

  def run_file_template
    @run_file_template ||= ERB.new(IO.readlines(settings.run_file_template).join)
  end

  def places_to_look_for_scenario_files
    [destination_folder_for_run_files]
  end

  def log
    settings.log
  end

end
