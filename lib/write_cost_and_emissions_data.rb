require_relative 'extract_overall_cost_and_emissions'
require 'fileutils'
require 'pathname'
require 'json'

class WriteCostAndEmissionsData
  
  attr_accessor :file_names
  attr_accessor :data_directory
  
  attr_accessor :files
  attr_accessor :extract_totals
  attr_accessor :data

  def initialize
    @extract_totals = ExtractOverallCostAndEmissions.new
    @files = {}
  end
  
  def run
    load_files
    extract_data
    write_data
    copy_across_template_to_data_directory
  end
  
  def load_files
    file_names.each.with_index do |file, i|
      unless File.exist?(file)
        puts "Can't find #{file} (#{File.expand_path(file)})"
        exit
      end
  
      case File.extname(file)
      when /\.gdx/i
        files[File.basename(file, '.*')] = file    
      else
        puts "Sorry, I don't recognise the format of #{file}"
        exit
      end
    end
  end
  
  def extract_data
    extract_totals.cases = files
    self.data = extract_totals.extract_overall_cost_and_emissions
  end
  
  def write_data
    list_of_cases = []


    data.each do |d|
      case_name = d[:name]
      list_of_cases.push(case_name)
      Pathname.new(File.join(data_directory, case_name)).mkpath
      File.open(File.join(data_directory, case_name, "costs-and-emissions-overview.json"), 'w') do |f|
        f.puts d.to_json
      end
    end  

    File.open(File.join(data_directory, "index.txt"), 'w') { |f| f.puts list_of_cases.join("\n") }
  end
  
  def copy_across_template_to_data_directory
    FileUtils.cp_r(Dir.glob(File.join(File.dirname(__FILE__),'..',"results-template",'*')),data_directory)
  end
end