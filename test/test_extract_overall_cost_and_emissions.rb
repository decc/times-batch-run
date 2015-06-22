require 'minitest/autorun'
require_relative '../lib/gdx'
require_relative '../lib/extract_overall_cost_and_emissions'


class TestExtractOverallCostAndEmissions < MiniTest::Test

  def setup
    @extract = ExtractOverallCostAndEmissions.new
    @extract.scenario_name = "caseA"
    @extract.gdx = Gdx.new(File.join(File.dirname(__FILE__), 'test.gdx'))
  end

  def test_result
    expected = {
        name: "caseA",
        cost: 10.121626581776,  # £trn
        ghg: {
          2010 => 661.2213888708541, # MtCO2e
          2011 => 640.1470923687849,
          2012 => 643.1591731505149,
          2015 => 645.185228738221,
          2020 => 603.376675230543,
          2025 => 607.997994993723,
          2030 => 619.389427532859,
          2035 => 631.2371228568829,
          2040 => 628.8435032979161,
          2045 => 646.432052429687,
          2050 => 686.615966107009,
          2055 => 683.441917078986,
          2060 => 679.553604628085
        },
        budget: {},
        scenarios: []
      }
    results = @extract.extract_overall_cost_and_emissions
    assert_equal expected, results
  end


end
