require 'optparse'
require_relative 'lib/create-list-of-cases'

create_list_of_cases = CreateListOfCases.new
create_list_of_cases.number_of_cases_to_generate = 200

OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} -n [number of cases] <possible_scenarios.tsv> <cases.tsv>"

  opts.on("-n", "--number-of-cases N", Integer, "Number of cases to generate from the possible_scenarios.tsv and put in the cases.tsv") do |n|
    create_list_of_cases.number_of_cases_to_generate = n
  end
end.parse!

create_list_of_cases.file_containing_possible_combinations_of_scenarios = ARGV[0] || "possible_scenarios.tsv"
create_list_of_cases.name_of_list_of_cases = ARGV[1] || 'cases.tsv'

create_list_of_cases.print_intent
create_list_of_cases.run!
create_list_of_cases.warn_about_missing_scenario_files
