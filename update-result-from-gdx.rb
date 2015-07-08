require_relative 'go'

batch_run = BatchRun.new
settings = batch_run.settings

settings.results_folder = ARGV[0]

batch_run.write_results(ARGV[1..-1])
