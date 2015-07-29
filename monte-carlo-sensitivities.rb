require 'optparse'
require_relative 'lib/monte_carlo_sensitivities'

m = MonteCarloSensitivities.new
m.number_of_cases_to_generate = 2000

OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} -n [minimum number of cases to generate ] <possible_scenarios.tsv> <cases.tsv>"

  opts.on("-n", "--number-of-cases N", Integer, "minimum number of cases to generate from the possible_scenarios.tsv") do |n|
    m.number_of_cases_to_generate = n
  end
end.parse!

m.file_containing_possible_combinations_of_scenarios = ARGV[0] || "possible_scenarios.tsv"
m.name_of_list_of_cases = ARGV[1] || 'cases.tsv'

m.run!
m.print_intent
