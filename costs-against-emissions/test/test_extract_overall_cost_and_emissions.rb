require 'minitest/autorun'
require_relative '../lib/extract_overall_cost_and_emissions'

$this_directory = File.dirname(__FILE__)

class TestExtractOverallCostAndEmissions < MiniTest::Test

  def setup
    @extract = ExtractOverallCostAndEmissions.new({ "caseA" => File.join($this_directory, 'test.gdx')})
  end

  def test_result
    expected = [
      {
        name: "caseA", 
        cost: 10.121626581776,  # £trn
        scenarios: [],
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
        }
      }
    ]
    results = @extract.extract_overall_cost_and_emissions
    assert_equal expected, results 
  end

  def test_merge_in_scenarios
    @extract.scenarios_in_case = { "caseA" => ["no_nucc", "base"] }
    expected = [
      {
        name: "caseA", 
        cost: 10.121626581776,  # £trn
        scenarios: ["no_nucc", "base"],
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
        }
      }
    ]
    results = @extract.extract_overall_cost_and_emissions
    assert_equal expected, results 
  end
  
  def test_missing_data
	mock_gdx = Minitest::Mock.new
	mock_gdx.expect(:symbol, [], [:OBJZ])
	@extract.cases.first[1] = mock_gdx
	assert_equal [], @extract.extract_overall_cost_and_emissions
	# FIXME: Will we ever not have ghg but have OBJZ? 
  end

end
