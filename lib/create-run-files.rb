require 'erb'
require_relative 'monte_carlo'

class CreateRunFiles
  include CommonMethods

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

        c.each.with_index do |scenario_name, column_number|
          next if column_number == 0 # Skip the name of the case
          if nil_scenario_file?(scenario_name)
            list_of_scenarios << "default_#{headers[column_number]}"
            next
          end

          list_of_scenarios << scenario_name.gsub(' ', '_').gsub('.', '_')

          unless scenario_file_exists?(scenario_name)
            missing_scenario_files[scenario_name] = true
          end

          list_of_dd_files << "$BATINCLUDE #{scenario_filename_from_name(scenario_name)}"
        end

        list_of_dd_files = list_of_dd_files.join("\n")
        f.puts run_file_template.result(binding)
      end
    end
  end


  def warn_about_missing_scenario_files
    if missing_scenario_files.size > 0
      puts
      puts "The following scenario files are missing from #{File.expand_path(destination_folder_for_run_files)}:"
      missing_scenario_files.each do |scenario_name, _|
        puts scenario_name
      end
      puts ""
      puts "Please check the spelling of the scenario in VEDA_FE and, if it is ok run VEDA_FE to generate them"
    end
  end

  def run_filename(case_name)
    File.expand_path(File.join(destination_folder_for_run_files, "#{case_name}.RUN"))
  end

  def load_list_of_cases
    # We do the join/split in order to sort out the various mac / windows line endings
    tsv = IO.readlines(name_of_file_containing_cases).join.split(/[\n\r]+/)
    # Delete empty lines
    tsv.delete_if { |line| line.strip == "" }
    # Delete lines starting with # (which we assume are comments)
    tsv.delete_if { |line| line.start_with?("#") }
    # Delete lines starting with "# (which we assume are comments, where the user entered # but Excel felt the need to add a quote in front
    tsv.delete_if { |line| line.start_with?('"#') }

    # Split the lines on tabs
    tsv.map! do |line|
      line.split(/\t+/)
    end

    @headers = tsv[0]
    @list_of_cases ||= tsv[1..-1] # [1..-1] Skip the title row
  end

  def run_file_template
    @run_file_template ||= ERB.new(IO.readlines(name_of_run_file_template).join)
  end

  def places_to_look_for_scenario_files
    [destination_folder_for_run_files]
  end

end
