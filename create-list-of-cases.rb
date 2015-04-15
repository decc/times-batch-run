if __FILE__ == $0 && ARGV.length == 1 && ARGV[0] =~ /help/i
puts <<END
#{__FILE__}

Glossary:
case - A single run of TIMES. Often people call these scenarios
scenario - Some assumptions or constraints in TIMES. 

A case consists of many scenarios put together.

This program takes a set of possible options for scenarios and
generates a list of cases that could be run

See possible_scenarios.tsv for the list of possible scenarios to use in the cases

Usage:
ruby #{__FILE__} <name_of_list_of_cases> <number_of_cases_to_generate> <file_containing_possible_combinations_of_scenarios>

Where:
name_of_list_of_cases - optional, default 'cases', this becomes a tsv listing scenarios, and within that list, the first part of the name of each case
number_of_cases_to_generate - optional, default 100, this is how many cases to generate
file_containing_possible_combinations_of_scenarios - optional, default 'possible_scenarios.tsv', this contains the possible scenarios
END
exit
end

class Array

  # Given a random array
  # ["title", "a", "b", "c"]
  # returns a, b or c randomly
  def random
    at(rand(length-1)+1)
  end
end

class CreateListOfCases

  attr_accessor :name_of_list_of_cases
  attr_accessor :number_of_cases_to_generate
  attr_accessor :file_containing_possible_combinations_of_scenarios
  attr_accessor :set_of_all_possible_scenarios
  attr_accessor :places_to_look_for_scenario_files
  attr_accessor :missing_scenario_files
  attr_accessor :cases

  def run!
    print_intent
    check_file_containing_possible_combinations_of_scenarios_exists
    load_set_of_all_possible_scenarios
    check_for_missing_scenario_files
    warn_about_missing_scenario_files
    create_list_of_cases
    write_cases_to_file
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
  end

  def check_file_containing_possible_combinations_of_scenarios_exists
    return if File.exist?(file_containing_possible_combinations_of_scenarios)
    puts "Can't find file containing possile scenarios: '#{File.expand_path(file_containing_possible_combinations_of_scenarios)}'" 
    exit
  end

  def check_for_missing_scenario_files
    @missing_scenario_files ||= []

    set_of_all_possible_scenarios.each do |scenario|
      scenario.each.with_index do |one_possible_scenario_file,i|
        next if i == 0 # The first element in each row is the name of the set
        next if scenario_file_exists?(one_possible_scenario_file)
        missing_scenario_files << one_possible_scenario_file 
      end
    end
  end

  def warn_about_missing_scenario_files
    if missing_scenario_files.length == 0
      puts "Found all the scenario files"

    elsif missing_scenario_files.length == count_of_possible_scenario_files
      puts "Can't find ANY of the scenario files in #{file_containing_possible_combinations_of_scenarios}."
      puts "This is ok, if you plan to move #{name_of_list_of_cases} somewhere else later,"
      puts "or if you plan to create the scenario files later"
    
    else
      puts "The following scenario files are missing:"
      puts missing_scenario_files.map { |scenario_name| scenario_filename_from_name(scenario_name) }
      puts
      puts "This is ok, if you plan to move #{name_of_list_of_cases} somewhere else later,"
      puts "or if you plan to create the scenario files later"
    end
  end

  def count_of_possible_scenario_files
    set_of_all_possible_scenarios.inject(0) do |count, set_of_scenarios| 
      count - 1 + set_of_scenarios.inject(0) do |count, possible_scenario, i|
        if possible_scenario.strip =~ /^nil$/i
          count
        else
          count + 1
        end
      end
    end 
  end

  def places_to_look_for_scenario_files 
    @places_to_look_for_scenario_files ||= [
      File.dirname(file_containing_possible_combinations_of_scenarios),
      File.dirname(name_of_list_of_cases)
    ]
  end

  def scenario_file_exists?(scenario_name)
    return true if scenario_name =~ /^nil$/i
    scenario_filename = scenario_filename_from_name(scenario_name)
    places_to_look_for_scenario_files.any? do |directory|
      File.exist?(File.join(directory, scenario_filename))
    end
  end

  def scenario_filename_from_name(scenario_name)
    "#{scenario_name.strip}.dd"
  end

  def create_list_of_cases
    @cases = []

    (1..number_of_cases_to_generate).each do |case_number|
      case_name = "#{File.basename(name_of_list_of_cases,'.*')}#{case_number}"
      case_scenarios = [case_name]
      set_of_all_possible_scenarios.each do |scenario|
        case_scenarios.push(scenario.random)
      end
      cases << case_scenarios
    end
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

if __FILE__ == $0
  create_list_of_cases = CreateListOfCases.new
  # Set our defaults
  create_list_of_cases.name_of_list_of_cases = ARGV[0] || 'cases.tsv'
  create_list_of_cases.number_of_cases_to_generate = (ARGV[1] && ARGV[1].to_i) || 100
  create_list_of_cases.file_containing_possible_combinations_of_scenarios = ARGV[2] || File.join(File.dirname(__FILE__), "possible_scenarios.tsv")
  create_list_of_cases.run!
end
