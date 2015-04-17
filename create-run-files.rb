unless __FILE__ == $0 
  $stderr.puts "#{__FILE__} should be run as a script, not called from other code"
  exit
end

if ARGV.length == 1 && ARGV[0] =~ /help/i
puts <<END
#{__FILE__}

This takes a list of cases and creates the run files that GAMS needs to 
use to execute them.

Usage:
ruby #{__FILE__} <destination_folder_for_run_files> <name_of_file_containing_cases> <name_of_run_file_template>

Where:
destination_folder_for_run_files - optional, default this folder, each row in the list of cases will become a run file in that folder
name_of_file_containing_cases    - optional, default cases.tsv, list of each case, where the first column is the name of the case, and remaining columns are #                                    scenarios to use in this case.
name_of_run_file_template - optional, the name of the template run file. Default is run-file-template.erb in the same folder as this script
END
exit
end

require_relative 'lib/create-run-files'

create_run_files = CreateRunFiles.new

# Set our defaults
create_run_files.destination_folder_for_run_files  = ARGV[0] || '.'
create_run_files.name_of_file_containing_cases = ARGV[1] || 'cases.tsv'
create_run_files.name_of_run_file_template = ARGV[2] || File.join(File.dirname(__FILE__),'run-file-template.erb')
create_run_files.run
create_run_files.warn_about_missing_scenario_files
