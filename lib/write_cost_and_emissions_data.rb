require_relative 'extract_overall_cost_and_emissions'
require 'fileutils'
require 'pathname'
require 'json'

class WriteCostAndEmissionsData
  
  attr_accessor :file_names
  attr_accessor :data_directory
  
  attr_accessor :data

  def initialize
    @data = {}
  end
  
  def run
    extract_data
    write_data
  end
  
  def extract_data
    file_names.each.with_index do |file, i|
      return unless gdx_file?(file)
      extract_data_from(file)
    end
  end

  def gdx_file?(file)
    unless File.exist?(file)
      puts "Can't find #{file} (#{File.expand_path(file)})"
      exit
    end

    unless File.extname(file) =~ /\.gdx/i
      puts "Sorry, I don't recognise the format of #{file}"
      exit
    end
    true
  end
  
  def extract_data_from(file)
    gdx = Gdx.new(file)
    name = File.basename(file,'.*')
    extractor = ExtractOverallCostAndEmissions.new
    extractor.gdx = gdx
    extractor.scenario_name = name
    data[name] = extractor.extract_overall_cost_and_emissions
  end
  
  def write_data
    data.each do |name, d|
      case_name = name
      Pathname.new(File.join(data_directory, case_name)).mkpath
      File.open(File.join(data_directory, case_name, "costs-and-emissions-overview.json"), 'w') do |f|
        f.puts d.to_json
      end
    end  
  end
  
end
