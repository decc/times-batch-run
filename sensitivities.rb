require 'optparse'
require_relative 'lib/sensitivities'

m = Sensitivities.new

OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__}  <possible_scenarios.tsv> <cases.tsv>"
end.parse!

m.file_containing_possible_combinations_of_scenarios = ARGV[0] || "possible_scenarios.tsv"
m.name_of_list_of_cases = ARGV[1] || 'cases.tsv'

m.run!
m.print_intent
