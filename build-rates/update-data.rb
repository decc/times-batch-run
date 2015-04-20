require_relative 'lib/extract_investment'
require 'json'

$this_directory = File.dirname(__FILE__)

if ARGV.length == 0
  files = {
    "ScenarioA" => File.join($this_directory, 'test', 'test.gdx'),
    "ScenarioB" => File.join($this_directory, 'test', 'test2.gdx')
  }
else
  files = {}
  ARGV.each do |gdx_file|
    files["s"+File.basename(gdx_file, '.*')] = gdx_file
  end
end

extract_investment = ExtractInvestment.new(files)
data = extract_investment.extract_new_capacity_with_cost_per_unit_sorted
json = data.to_json

File.open(File.join($this_directory, 'data.json'), 'w') { |f| f.puts json }
