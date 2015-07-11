require 'logger'
require 'optparse'

require_relative 'lib/extract_results'

extract_results = ExtractResults.new
settings = extract_results.settings

OptionParser.new do |opts|

  opts.banner = "Usage: #{File.basename(__FILE__)} [options] [results folder] [gdx file] [another gdx file] [more gdx files...]"
end.parse!

settings.log = Logger.new(STDOUT)
settings.results_folder = ARGV[0]

extract_results.create_results_folder_if_doesnt_exist
extract_results.copy_across_html_if_no_index_html

ARGV[1..-1].each do |gdx_file|
  extract_results.write_results(gdx_file)
end
