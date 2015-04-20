require_relative 'lib/write_cost_and_emissions_data'

# FIXME: DOCUMENT THIS!

$this_directory = File.dirname(__FILE__)

# No arguments given, then just use some test data
if ARGV.length == 0
  ARGV[0] = File.join($this_directory, 'test', 'test.tsv')
  ARGV[1] = File.join($this_directory, 'test', 'test.gdx')
  ARGV[2] = File.join($this_directory, 'test', 'test2.gdx')
end

writer = WriteCostAndEmissionsData.new
writer.file_names = ARGV
writer.data_directory = File.join($this_directory, 'example')