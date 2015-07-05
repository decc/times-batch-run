require 'erb'
require_relative 'scenario_file_methods'
require_relative 'list_of_cases'

class CreateRunFiles
  include ScenarioFileMethods

  attr_accessor :destination_folder_for_run_files
  attr_accessor :name_of_file_containing_cases
  attr_accessor :name_of_run_file_template
  attr_accessor :places_to_look_for_scenario_files
  attr_accessor :missing_scenario_files
  attr_reader   :list_of_cases
  attr_reader   :headers

  def run
    load_list_of_cases
    @missing_scenario_files = {}

    list_of_cases.each do |c|

      puts "Generating #{run_filename(c.first)}"

      File.open(run_filename(c.first), 'w') do |f|

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
        f.puts run_file_template.result(binding)
      end
    end
  end


  def warn_about_missing_scenario_files
    return if missing_scenario_files.size == 0
    puts
    puts "The following scenario files are missing from #{File.expand_path(destination_folder_for_run_files)}:"
    missing_scenario_files.each do |scenario_name, _|
      puts scenario_name
    end
    puts ""
    puts "Please check the spelling of the scenario in VEDA_FE and, if it is ok run VEDA_FE to generate them"
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
    @run_file_template ||= ERB.new(IO.readlines(name_of_run_file_template).join)
  end

  def places_to_look_for_scenario_files
    [destination_folder_for_run_files]
  end

end
