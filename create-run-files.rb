# create_run_files.rb
#
# This takes a list of cases and creates the run files that GAMS needs to 
# use to execute them.
#
# Usage:
# ruby create_run_files.rb <destination_folder_for_run_files> <name_of_file_containing_cases> <name_of_run_file_template>
#
# Where:
# destination_folder_for_run_files - optional, default this folder, each row in the list of cases will become a run file in that folder
# name_of_file_containing_cases    - optional, default cases.tsv, list of each case, where the first column is the name of the case, and remaining columns are #                                    scenarios to use in this case.
# name_of_run_file_template - optional, the name of the template run file. Default is run-file-template.erb in the same folder as this script

require 'erb'

class CreateRunFiles
  attr_accessor :destination_folder_for_run_files
  attr_accessor :name_of_file_containing_cases
  attr_accessor :name_of_run_file_template

  def run
    list_of_cases = IO.readlines(name_of_file_containing_cases).join.split(/[\n\r]+/).map { |r| r.split("\t") }
    list_of_cases.shift # Remove the title row

    list_of_cases.each do |c|

      run_filename = File.expand_path(File.join(destination_folder_for_run_files, "#{c.first}.RUN"))

      puts "Generating #{run_filename}"

      File.open(run_filename, 'w') do |f|
        list_of_dd_files = c[1..-1].map do |dd| 
          if dd.strip =~ /^NIL$/i
            ""
          else
            "$BATINCLUDE #{dd.strip}.dd" 
          end
        end.join("\n") 
        f.puts run_file_template.result(binding)
      end
    end
  end

  def run_file_template
    @run_file_template ||= ERB.new(IO.readlines(name_of_run_file_template).join)
  end

end

create_run_files = CreateRunFiles.new
create_run_files.destination_folder_for_run_files  = ARGV[0] || '.'
create_run_files.name_of_file_containing_cases = ARGV[1] || 'cases.tsv'
create_run_files.name_of_run_file_template = ARGV[2] || File.join(File.dirname(__FILE__),'run-file-template.erb')
create_run_files.run
