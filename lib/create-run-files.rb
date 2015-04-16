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
