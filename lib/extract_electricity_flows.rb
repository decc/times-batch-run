require_relative 'gdx'

class ExtractElectricityFlows

  PROCESS_NAME_REGEX = /^(.*?)\d*$/ # This is used to trim the numbers off the end of process names
  YEARS = [2011, 2012, 2015, 2020, 2025, 2030, 2035, 2040, 2045, 2050, 2055, 2060] # The gdx data doesn't include zero values, so we have to include them manually. <sigh>
  ELECTRICITY_COMMODITIES = %w{ ELCGEN }

  attr_accessor :gdx
  attr_accessor :scenario_name
  attr_accessor :results
  attr_accessor :commodities_included
  
  def extract_results
    extract_electricity_flows
  end

  def extract_electricity_flows
    extract_all_flows
    filter_electricity_flows
    aggregate_electricity_flows
    results
  end

  private

  attr_accessor :flows_out

  def extract_all_flows
    @flows_out = gdx.symbol(:F_OUT)
  end

  def filter_electricity_flows
    @flows_out = flows_out.select { |flow| include_commodity?(flow[:c]) }
  end

  def include_commodity?(commodity)
    ELECTRICITY_COMMODITIES.include?(commodity)
  end

  def aggregate_electricity_flows
    processes_by_year = results[:processes_by_year]
    flows_out.each do |flow|
      process_name = combined_process_name(flow[:p])
      commodity_name = flow[:c]
      value = flow[:val] / 3.6 # to get from PJ to TWh
      year = flow[:t]
      processes_by_year[process_name][year] += value
    end
  end

  def results
    @results ||= {
      :name => scenario_name,
      :processes_by_year =>  Hash.new() { |hash, new_key| hash[new_key] = Hash.new(0) }
    }
  end
  
  # Strips the trailing 00 01 02 off the end of process names to group them a bit
  def combined_process_name(process_name)
    process_name[PROCESS_NAME_REGEX,1]
  end
  
end
