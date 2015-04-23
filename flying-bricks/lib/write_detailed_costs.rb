require_relative 'extract_detailed_costs'
require 'fileutils'
require 'pathname'
require 'json'

class WriteDetailedCosts
  
  attr_accessor :data_directory
  attr_accessor :file_names
  
  def run
    list_of_cases = []
    extract_investment = ExtractDetailedCosts.new
    file_names.each do |gdx_file|
      case_name = File.basename(gdx_file, '.*')
      extract_investment.scenario_name = case_name
      extract_investment.gdx = Gdx.new(gdx_file)
      data = extract_investment.extract_detailed_costs
      list_of_cases.push(case_name)
      Pathname.new(File.join(data_directory, case_name)).mkpath
      File.open(File.join(data_directory, case_name, "detailed-costs.json"), 'w') do |f|
        f.puts data.to_json
      end
    end
    File.open(File.join(data_directory, "index.txt"), 'w') { |f| f.puts list_of_cases.join("\n") }
    FileUtils.cp_r(Dir.glob(File.join(File.dirname(__FILE__),'..', "template",'*')),data_directory)
  end
end