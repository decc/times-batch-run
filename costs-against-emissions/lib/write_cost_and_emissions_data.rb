require_relative 'extract_overall_cost_and_emissions'
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
      when /\.tsv/i
        scenarios_in_cases = IO.readlines(file)
          .join
          .split(/[\n\r]+/) # Deal with unix and windows line endings
          .map { |r| r.split("\t") } # Tab separated
    
        titles = scenarios_in_cases.shift # Remove the title row
  
        scenarios_in_cases.each do|row|
          row.map!.with_index { |t,i| t =~ /NIL/i ? "default_#{titles[i].gsub(" ","_")}" : t  } # The NILs aren't very informative
          extract_totals.scenarios_in_case[row.shift] = row
        end
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
      File.open(File.join(data_directory, "#{case_name}.json"), 'w') do |f|
        f.puts d.to_json
      end
    end  

    File.open(File.join(data_directory, "index.txt"), 'w') { |f| f.puts list_of_cases.join("\n") }
  end
end