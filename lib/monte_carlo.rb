require_relative 'encode_case'
require_relative 'scenario_file_methods'

class MonteCarlo
  include ScenarioFileMethods
  include EncodeCase

  attr_accessor :name_of_list_of_cases
  attr_accessor :number_of_cases_to_generate
  attr_accessor :file_containing_possible_combinations_of_scenarios
  attr_accessor :set_of_all_possible_scenarios
  attr_accessor :places_to_look_for_scenario_files
  attr_accessor :missing_scenario_files
  attr_accessor :cases
  attr_accessor :prefix
  attr_accessor :number_of_scenarios_per_set

  def run!
    set_prefix
    check_file_containing_possible_combinations_of_scenarios_exists
    load_set_of_all_possible_scenarios
    create_list_of_cases
    write_cases_to_file
  end

  def set_prefix
    @prefix ||= File.basename(name_of_list_of_cases,'.*')
  end

  def load_set_of_all_possible_scenarios
    # We do the join/split in order to sort out the various mac / windows line endings
    @set_of_all_possible_scenarios = IO.readlines(file_containing_possible_combinations_of_scenarios).join.split(/[\r\n]+/)

    # Delete empty lines
    set_of_all_possible_scenarios.delete_if { |line| line.strip == "" }
    # Delete lines starting with # (which we assume are comments)
    set_of_all_possible_scenarios.delete_if { |line| line.start_with?("#") }
    # Delete lines starting with "# (which we assume are comments, where the user entered # but Excel felt the need to add a quote in front
    set_of_all_possible_scenarios.delete_if { |line| line.start_with?('"#') }

    # Split the lines on tabs
    set_of_all_possible_scenarios.map! do |line|
      line.split(/\t+/)
    end
    # Set of scenarios now looks like:
    # [
    #   [ "nuclear", "one possible nuclear scenario file name", "another possible nuclear scenario name", ...],
    #   [ "ccs", "one possible ccs scenario file name", "another possible css scenario name", ...],
    #   ...
    # ]
    #
    @number_of_scenarios_per_set = set_of_all_possible_scenarios.map do |sets|
      sets.length - 1
    end
  end

  def check_file_containing_possible_combinations_of_scenarios_exists
    return if File.exist?(file_containing_possible_combinations_of_scenarios)
    puts "Can't find file containing possile scenarios: '#{File.expand_path(file_containing_possible_combinations_of_scenarios)}'" 
    exit
  end

  def count_of_possible_scenario_files
    set_of_all_possible_scenarios.inject(0) do |count, set_of_scenarios| 
      count - 1 + set_of_scenarios.inject(0) do |count, possible_scenario, i|
        if nil_scenario_file?(possible_scenario)
          count
        else
          count + 1
        end
      end
    end 
  end

  def create_list_of_cases
    @cases = []

    number_of_cases_to_generate.times do
      case_scenario_indexes = number_of_scenarios_per_set.map { |n| rand(n) }
      case_scenarios = case_scenario_indexes.map.with_index { |column, row| set_of_all_possible_scenarios[row][column+1] }
      case_name = case_name_for(case_scenario_indexes)
      cases << [case_name].concat(case_scenarios)
    end
    cases.sort_by! { |c| c.first } # Sort the cases alphabetically by the case name
  end
  

  
  def case_name_for(scenarios)
    "#{prefix}#{encode(scenarios,number_of_scenarios_per_set).to_s(36)}" # Encode the scenarios and write in base 36
  end

  def write_cases_to_file
    File.open(name_of_list_of_cases,'w') do |f|
      f.puts "CaseName\t"+set_of_all_possible_scenarios.map(&:first).join("\t")
      cases.each do |c|
        f.puts c.join("\t")
      end
    end
  end

  def print_intent
    puts "Generating #{number_of_cases_to_generate} cases from #{File.expand_path(file_containing_possible_combinations_of_scenarios)} and putting them in #{File.expand_path(name_of_list_of_cases)}"
  end

end
