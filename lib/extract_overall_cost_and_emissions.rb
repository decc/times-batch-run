class ExtractOverallCostAndEmissions

  attr_accessor :gdx
  attr_accessor :scenario_name

  def extract_overall_cost_and_emissions
    results = {}
    results[:name] = scenario_name

    cost = gdx.objz

    results[:cost] = cost / 1.0e6 # Convert from £M to £trn
    results[:ghg] = ghg = {}
    results[:budget] = budget = {}
    results[:scenarios] = gdx.scenarios

    gdx.symbol(:AGG_OUT).each do |d|
      next unless d[:c] == 'GHGTOT'
      ghg[d[:t]] = d[:val]/1000.0 # Convert from ktCO2e to MtCO2e
    end

    gdx.symbol(:COM_BNDNET).each do |d|
      next unless d[:com] == 'GHG-NO-IAS-YES-LULUCF-NET'
      budget[d[:allyear]] = (d[:val]*5/1000) # Convert from ktCO2e/yr to MtCO2e over 5 years
    end

    results
  end

end
