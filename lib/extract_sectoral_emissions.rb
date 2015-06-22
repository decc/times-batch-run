require_relative 'gdx'

class ExtractSectoralEmissions

  # FIXME: Extract this duplicate years setting
  YEARS = [2011, 2012, 2015, 2020, 2025, 2030, 2035, 2040, 2045, 2050, 2055, 2060] # The gdx data doesn't include zero values, so we have to include them manually. <sigh>

  attr_accessor :gdx
  attr_accessor :scenario_name
  attr_accessor :results

  def initialize
    setup_commodities_to_aggregate
  end
  
  def extract_results
    extract_sectoral_emissions
  end

  def extract_sectoral_emissions
    setup_results
    extract_all_flows
    filter_flows
    aggregate_flows
    results
  end

  private

  attr_accessor :commodities_to_include
  attr_accessor :aggregation
  attr_accessor :flows_in
  attr_accessor :flows_out

  # FIXME: Duplicates with the extract_detailed_emissions
  def setup_commodities_to_aggregate
    @commodities_to_include = {}
    @aggregation = {}

    sectors = %w{AGR TRA RES RSR HYG ELC SER PRC UPS IND}
    gases = %w{CO2 CH4 N2O HFC}
    types = %w{N P}
    sectors.each do |sector|
      gases.each do |gas|
        types.each do |type|
          name = sector+gas+type
          @commodities_to_include[name] = true
          @aggregation[name] = sector
          
        end
      end
    end
    @commodities_to_include["Traded-Emission-ETS"] = true
    @commodities_to_include["Traded-Emission-Non-ETS"] = true
    @commodities_to_include
  end

  def setup_results
    @results = {
      :name => scenario_name,
      :processes_by_year =>  Hash.new() { |hash, new_key| hash[new_key] = Hash.new(0) }
    }
  end

  def extract_all_flows
    @flows_in = gdx.symbol(:F_IN)
    @flows_out = gdx.symbol(:F_OUT)
  end

  def filter_flows
    flows_in.delete_if { |flow| exclude_commodity?(flow[:c]) }
    flows_out.delete_if { |flow| exclude_commodity?(flow[:c]) }
  end

  def exclude_commodity?(commodity)
    not commodities_to_include.has_key?(commodity)
  end

  def aggregate_flows
    aggregate(flows_out)
    aggregate(flows_in, true)
  end

  def aggregate(attribute, negative = false)
    processes_by_year = results[:processes_by_year]
    attribute.each do |flow|
      commodity_name = flow[:c]
      if commodity_name =~ /^Traded-Emissions/i
        value = -flow[:val] / 1000.0 # Reverse the direction of traded flows
      else
        value = flow[:val] / 1000.0 # * 1000 in order to turn into MtCO2e
      end
      value = -value if negative
      year = flow[:t]
      name = aggregation[commodity_name] || commodity_name
      processes_by_year[name][year] += value
    end
  end
end
