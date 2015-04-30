require_relative 'lib/write_build_rates'

if ARGV.length == 0
  ARGV[0] = File.join(File.dirname(__FILE__), 'results-example')
  ARGV[1] = File.join(File.dirname(__FILE__), 'test', 'test.gdx')
  ARGV[2] = File.join(File.dirname(__FILE__), 'test', 'test2.gdx')
end

write_build_rates = WriteBuildRates.new
write_build_rates.data_directory = ARGV[0]
write_build_rates.file_names = ARGV.slice(1..-1)
write_build_rates.run


