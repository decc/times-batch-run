require 'minitest/autorun'
require_relative '../lib/extract_detailed_costs'
require 'pp'

$this_directory = File.dirname(__FILE__)

class TestExtractDetailedCosts < MiniTest::Test

  def setup
    @extract_detailed_costs = ExtractDetailedCosts.new
    @extract_detailed_costs.scenario_name = "ScenarioA"
    @extract_detailed_costs.gdx = Gdx.new(File.join($this_directory, 'test.gdx'))
  end

  def test_detailed_costs
    actual = @extract_detailed_costs.extract_detailed_costs
    assert_kind_of(Hash, actual)
    assert_equal("ScenarioA", actual[:name])
    assert_kind_of(Hash, actual[:processes_by_year])
    assert_equal(3.72592265795458, actual[:processes_by_year]["TFSLDST"][2010])
    assert_equal(72.8425866230033, actual[:processes_by_year]["TFSLDST"]["npv"])
  end


  # Discounted_sum turns a single value for, say 2050
  # into the total, discounted value for 2048-2052
  def test_discounted_sum
    input = { 2050 => 10}
    expected = { 2050 => (10*5*((1.0-0.035)**(2050-2010)))} # Roughly 3.5% discounted to 2010, times 5 years
    actual = @extract_detailed_costs.discounted_sum(input)
    
    assert_in_delta(expected[2050], actual[2050], 2)
  end

end

