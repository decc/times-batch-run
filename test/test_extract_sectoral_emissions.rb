require 'minitest/autorun'
require_relative '../lib/extract_sectoral_emissions'
require 'pp'

$this_directory = File.dirname(__FILE__)

class TestExtractSectoralEmissions < MiniTest::Test

  def setup
    @extractor = ExtractSectoralEmissions.new
    @extractor.scenario_name = "ScenarioA"
    @extractor.gdx = Gdx.new(File.join($this_directory, 'test.gdx'))
  end

  def test_extract_results
    actual = @extractor.extract_results
    assert_kind_of(Hash, actual)
    assert_equal("ScenarioA", actual[:name])
    assert_kind_of(Hash, actual[:processes_by_year])
    assert_equal(43.958623705868696, actual[:processes_by_year]["AGR"][2010])
  end
end

