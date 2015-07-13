require_relative 'gdx'

class ExtractCarbonPrices

  SYMBOLS_TO_CHECK_FOR_PRICE = %w{ EQE_COMBAL EQG_COMBAL EQL_COMBAL EQE_COMNET EQL_COMNET EQG_COMNET }

  attr_accessor :gdx
  attr_accessor :scenario_name
  attr_accessor :results
  
  def extract_results
    extract_carbon_prices
  end

  def extract_carbon_prices
    extract_all_symbols
    filter_carbon_prices
    transform_carbon_prices 
  end

  private

  attr_accessor :symbols

  def extract_all_symbols
    @symbols = SYMBOLS_TO_CHECK_FOR_PRICE.map { |symbol| gdx.marginals(symbol) }
  end

  def filter_carbon_prices
    @symbols = symbols.map do |symbol|
      symbol.select { |row| include_commodity?(row[:c]) }
    end
  end

  def include_commodity?(commodity)
    commodity =~ /^(GHG|CO2|N2O|CH4|HFC)/
  end

  def transform_carbon_prices
    prices = Hash.new { |hash, new_key| hash[new_key] = Hash.new { |hash, new_key| hash[new_key] = 0.0 } }

    symbols.each do |marginals|
      marginals.each do |marginal|
        commodity = marginal[:c]
        year = marginal[:allyear]
        value = marginal[:val] * -1000.0 # £M/ktCO2e to £/tCO2e / Negative because if loosening the constraint lowers the Objective value, then the carbon price must be positive
        prices[commodity][year] = prices[commodity][year] + value
      end
    end
    { :name => scenario_name, :prices => prices }
  end

  def results
    @results ||= {
      :name => scenario_name,
      :prices =>  Hash.new() { |hash, new_key| hash[new_key] = Hash.new(0) }
    }
  end
  
  # Strips the trailing 00 01 02 off the end of process names to group them a bit
  def combined_process_name(process_name)
    process_name[PROCESS_NAME_REGEX,1]
  end
  
end
