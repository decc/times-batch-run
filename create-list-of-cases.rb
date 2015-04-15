unless __FILE__ == $0 
  $stderr.puts "#{__FILE__} should be run as a script, not called from other code"
  exit
end

if ARGV.length == 1 && ARGV[0] =~ /help/i
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

require_relative 'lib/create-list-of-cases'

create_list_of_cases = CreateListOfCases.new
# Set our defaults
create_list_of_cases.name_of_list_of_cases = ARGV[0] || 'cases.tsv'
create_list_of_cases.number_of_cases_to_generate = (ARGV[1] && ARGV[1].to_i) || 100
create_list_of_cases.file_containing_possible_combinations_of_scenarios = ARGV[2] || File.join(File.dirname(__FILE__), "possible_scenarios.tsv")
create_list_of_cases.run!
