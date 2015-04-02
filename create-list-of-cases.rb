# create-list-of-cases.rb
#
# Glossary:
# case - A single run of TIMES. Often people call these scenarios
# scenario - Some assumptions or constraints in TIMES. 
#
# A case consists of many scenarios put together.
#
# This program takes a set of possible options for scenarios and
# generates a list of cases that could be run
#
# See possible_scenarios.tsv for the list of possible scenarios to use in the cases
#
# Usage:
# ruby create-list-of-cases.rb <name_of_list_of_cases> <number_of_cases_to_generate> <possible_scenarios_file>
# 
# Where:
# name_of_list_of_cases - optional, default 'cases', this becomes a tsv listing scenarios, and within that list, the first part of the name of each case
# number_of_cases_to_generate - optional, default 100, this is how many cases to generate
# possible_scenarios_file - optional, default 'possible_scenarios.tsv', this contains the possible scenarios

name_of_list_of_cases = ARGV[0] || 'cases'
number_of_cases_to_generate = ARGV[1].to_i || 100
set_of_scenarios_file = ARGV[2] || File.join(File.dirname(__FILE__), "possible_scenarios.tsv")

puts "Generating #{number_of_cases_to_generate} cases from #{File.expand_path(set_of_scenarios_file)} and putting them in #{File.expand_path(name_of_list_of_cases)}.tsv"

unless File.exist?(set_of_scenarios_file)
  puts "Can't find scenario file #{File.expand_path(set_of_scenarios_file)}" 
  exit
end

set_of_scenarios = IO.readlines(set_of_scenarios_file).join.split(/[\r\n]+/)
set_of_scenarios.delete_if { |line| line.strip == "" || line.start_with?("#") || line.start_with?('"#') }
set_of_scenarios.map! do |line|
  line.split(/\t+/)
end

class Array

  # Given a random array
  # ["title", "a", "b", "c"]
  # returns a, b or c randomly
  def random
    at(rand(length-1)+1)
  end
end


cases = []

(1..number_of_cases_to_generate).each do |case_number|
  case_name = "#{name_of_list_of_cases}#{case_number}"
  case_scenarios = [case_name]
  set_of_scenarios.each do |scenario|
    case_scenarios.push(scenario.random)
  end
  cases << case_scenarios
end

File.open("#{name_of_list_of_cases}.tsv",'w') do |f|
  f.puts "CaseName\t"+set_of_scenarios.map(&:first).join("\t")
  cases.each do |c|
    f.puts c.join("\t")
  end
end
