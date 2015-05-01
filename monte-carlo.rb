require 'optparse'
require_relative 'lib/monte_carlo'

m = MonteCarlo.new
m.number_of_cases_to_generate = 200

OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} -n [number of cases] <possible_scenarios.tsv> <cases.tsv>"

  opts.on("-n", "--number-of-cases N", Integer, "Number of cases to generate from the possible_scenarios.tsv and put in the cases.tsv") do |n|
    m.number_of_cases_to_generate = n
  end
end.parse!

m.file_containing_possible_combinations_of_scenarios = ARGV[0] || "possible_scenarios.tsv"
m.name_of_list_of_cases = ARGV[1] || 'cases.tsv'

m.print_intent
m.run!
m.warn_about_missing_scenario_files
