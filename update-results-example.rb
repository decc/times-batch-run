require_relative 'go'

this_folder = File.expand_path(File.dirname(__FILE__))

if __FILE__ == $0
  batch_run = BatchRun.new
  settings = batch_run.settings

  settings.gams_working_folder = this_folder
  settings.results_folder = File.join(this_folder, "results-example")
  settings.list_of_cases_files = [File.join(this_folder,"test", "test.tsv")]
  settings.gams_save_folder = File.join(this_folder, "test")

  batch_run.run_results_only
end
