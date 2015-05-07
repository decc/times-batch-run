require_relative 'gdx'

class ExtractOverallCostAndEmissions

  attr_accessor :cases
  attr_accessor :scenarios_in_case

  def initialize(new_cases = nil)
    self.scenarios_in_case = Hash.new([])
    self.cases = new_cases if new_cases
  end

  # FIXME: Not good that self.cases = self.cases will fail
  def cases=(new_cases)
    @cases = new_cases.map do |case_name, gdx_filename|
      [case_name, Gdx.new(gdx_filename)]
    end
  end

  def extract_overall_cost_and_emissions
    results = []
    cases.each do |name, gdx|
      results << extract_overall_cost_and_emissions_from(name, gdx)
    end
    results.compact # compact removes nils. Nils are created when scenarios have missing data
  end

  def extract_overall_cost_and_emissions_from(name, gdx)
    p name, gdx.scenarios
    results = { name: name }
	  cost = gdx.objz
    results[:cost] = cost / 1.0e6 # Convert from £M to £trn
    results[:ghg] = ghg = {}
    results[:scenarios] = gdx.scenarios
    gdx.symbol(:AGG_OUT).each do |d|
      ghg[d[:t]] = d[:val]/1000.0 # Convert from ktCO2e to MtCO2e
    end
    results
  end

end
