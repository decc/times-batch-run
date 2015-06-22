require 'minitest/autorun'
require_relative '../lib/extract_detailed_emissions'
require 'pp'

$this_directory = File.dirname(__FILE__)

class TestExtractDetailedEmissions < MiniTest::Test

  def setup
    @extract_detailed_emissions = ExtractDetailedEmissions.new
    @extract_detailed_emissions.scenario_name = "ScenarioA"
    @extract_detailed_emissions.gdx = Gdx.new(File.join($this_directory, 'test.gdx'))
  end

  def test_detailed_emissions
    actual = @extract_detailed_emissions.extract_detailed_emissions
    assert_kind_of(Hash, actual)
    assert_equal("ScenarioA", actual[:name])
    assert_kind_of(Hash, actual[:processes_by_year])
    assert_equal(4.789202734156231, actual[:processes_by_year]["TFSLDST"][2010])
  end


end

