require_relative 'gdx'

class ExtractCarbonPrices

  SYMBOLS_TO_CHECK_FOR_PRICE = %w{ PAR_COMBALEM PAR_COMBALGM PAR_COMNETM PAR_COMPRDM }

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
    @symbols = SYMBOLS_TO_CHECK_FOR_PRICE.map { |symbol| gdx.symbol(symbol) }
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
    prices = Hash.new { |hash, new_key| hash[new_key] = {} }

    symbols.each do |marginals|
      marginals.each do |marginal|
        commodity = marginal[:c]
        year = marginal[:allyear]
        value = marginal[:val] * -1000.0 # £M/ktCO2e to £/tCO2e / Negative because if loosening the constraint lowers the Objective value, then the carbon price must be positive
	if prices[commodity][year]
		if value == 0
			# leave it alone, it will be a bigger absolute number
		elsif value > 0
           		prices[commodity][year] = [prices[commodity][year], value].max
		elsif prices[commodity][year] < 0
           		prices[commodity][year] = [prices[commodity][year], value].min
		else
			# leave it alone it will be a postitive number
		end
	else
        	prices[commodity][year] = value
	end
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
