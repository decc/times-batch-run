require_relative 'gdx'

class ExtractDetailedEmissions

  PROCESS_NAME_REGEX = /^(.*?)\d*$/ # This is used to trim the numbers off the end of process names
  YEARS = [2011, 2012, 2015, 2020, 2025, 2030, 2035, 2040, 2045, 2050, 2055, 2060] # The gdx data doesn't include zero values, so we have to include them manually. <sigh>

  attr_accessor :gdx
  attr_accessor :scenario_name
  attr_accessor :results
  
  def extract_detailed_emissions
    extract_all_flows
    filter_emissions_flows
    aggregate_emissions_flows
    results
  end

  private

  attr_accessor :flows_in
  attr_accessor :flows_out

  def extract_all_flows
    @flows_in = gdx.symbol(:F_IN)
    @flows_out = gdx.symbol(:F_OUT)
  end

  def filter_emissions_flows
    flows_in.delete_if { |flow| exclude_commodity?(flow[:c]) }
    flows_out.delete_if { |flow| exclude_commodity?(flow[:c]) }
  end

  def exclude_commodity?(commodity)
    not commodities_to_include.has_key?(commodity)
  end

  def commodities_to_include
    return @commodities_to_include if @commodities_to_include
    @commodities_to_include = {}
    sectors = %w{AGR TRA RES RSR HYG ELC SER PRC UPS IND}
    gases = %w{CO2 CH4 N2O HFC}
    types = %w{N P}
    sectors.each do |sector|
      gases.each do |gas|
        types.each do |type|
          @commodities_to_include[sector+gas+type] = true
        end
      end
    end
    @commodities_to_include["Traded-Emission-ETS"] = true
    @commodities_to_include["Traded-Emission-Non-ETS"] = true
    @commodities_to_include
  end

  def aggregate_emissions_flows
    processes_by_year = results[:processes_by_year]
    flows_out.each do |flow|
      process_name = combined_process_name(flow[:p])
      commodity_name = flow[:c]
      if flow[:c] =~ /^Traded-Emissions/i
        value = -flow[:val] / 1000.0 # Reverse the direction of traded flows
      else
        value = flow[:val] / 1000.0 # * 1000 in order to turn into MtCO2e
      end
      year = flow[:t]
      processes_by_year[process_name][year] += value
    end
    flows_in.each do |flow|
      process_name = combined_process_name(flow[:p])
      commodity_name = flow[:c]
      if flow[:c] =~ /^Traded-Emissions/i
        value = flow[:val] / 1000.0 # Reverse the direction of traded flows
      else
        value = -flow[:val] / 1000.0 # Negative because a flow in *1000 in order to turn into MtCO2e
      end
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
