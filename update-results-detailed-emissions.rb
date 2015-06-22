require_relative 'lib/write_detailed_emissions'

# FIXME: DOCUMENT THIS!

$this_directory = File.dirname(__FILE__)

# No arguments given, then just use some test data
if ARGV.length == 0
  ARGV[0] = File.join(File.dirname(__FILE__), 'results-example')
  ARGV[1] = File.join($this_directory, 'test', 'test.gdx')
  ARGV[2] = File.join($this_directory, 'test', 'test2.gdx')
end

writer = WriteDetailedEmissions.new
writer.data_directory = ARGV[0]
writer.file_names = ARGV.slice(1..-1)
writer.run
