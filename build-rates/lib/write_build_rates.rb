require_relative 'extract_investment'
require 'json'
require 'fileutils'
require 'pathname'

class WriteBuildRates
  attr_accessor :data_directory
  attr_accessor :file_names
  
  def run
    list_of_cases = []
    file_names.each do |gdx_file|
      case_name = File.basename(gdx_file, '.*')
      files = { case_name => gdx_file }
      extract_investment = ExtractInvestment.new(files)
      data = extract_investment.extract_new_capacity_with_cost_per_unit_sorted
      list_of_cases.push(case_name)
      Pathname.new(File.join(data_directory, case_name)).mkpath
      File.open(File.join(data_directory, case_name, "build-rates.json"), 'w') do |f|
        f.puts data.to_json
      end
      File.open(File.join(data_directory, "index.txt"), 'w') { |f| f.puts list_of_cases.join("\n") }
      FileUtils.cp_r(Dir.glob(File.join( File.dirname(__FILE__), '..' , "template",'*')),data_directory)
    end    
  end
end
