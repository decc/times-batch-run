require 'minitest/autorun'
require_relative '../lib/gdx'

$this_directory = File.dirname(__FILE__)

class TestGDX < MiniTest::Test

  def setup
    @gdx = Gdx.new(File.join($this_directory, 'test.gdx'))
  end

  def test_objective_function_cost
    expected =  {
      :val=>10121626.581776 # Quantity, a cost, probably £M (i.e., £10trn in this case)
      # Plausability check: £10trn / 50 years = £200 billion a year, and we spend about £100 billion on fuel
      # £10trn needs adjusting up for discounting (doubling?)
      # £100bn needs the cost of equipement (especially cars adding on)
    }
    assert_equal expected, @gdx.symbol(:OBJZ).first
  end

  def test_total_emissions
    expected = [
      {:r=>"UK", :t=>2010, :c=>"GHGTOT", :ts=>"ANNUAL", :val=>661221.388870854}, # Unit is kt CO2e
      {:r=>"UK", :t=>2011, :c=>"GHGTOT", :ts=>"ANNUAL", :val=>640147.092368785}, # Plausability check: 2010 = 661 MtCO2e, Statistics 606 MtCO2e
      {:r=>"UK", :t=>2012, :c=>"GHGTOT", :ts=>"ANNUAL", :val=>643159.173150515},
      {:r=>"UK", :t=>2015, :c=>"GHGTOT", :ts=>"ANNUAL", :val=>645185.228738221},
      {:r=>"UK", :t=>2020, :c=>"GHGTOT", :ts=>"ANNUAL", :val=>603376.675230543},
      {:r=>"UK", :t=>2025, :c=>"GHGTOT", :ts=>"ANNUAL", :val=>607997.994993723},
      {:r=>"UK", :t=>2030, :c=>"GHGTOT", :ts=>"ANNUAL", :val=>619389.427532859},
      {:r=>"UK", :t=>2035, :c=>"GHGTOT", :ts=>"ANNUAL", :val=>631237.122856883},
      {:r=>"UK", :t=>2040, :c=>"GHGTOT", :ts=>"ANNUAL", :val=>628843.503297916},
      {:r=>"UK", :t=>2045, :c=>"GHGTOT", :ts=>"ANNUAL", :val=>646432.052429687},
      {:r=>"UK", :t=>2050, :c=>"GHGTOT", :ts=>"ANNUAL", :val=>686615.966107009},
      {:r=>"UK", :t=>2055, :c=>"GHGTOT", :ts=>"ANNUAL", :val=>683441.917078986},
      {:r=>"UK", :t=>2060, :c=>"GHGTOT", :ts=>"ANNUAL", :val=>679553.604628085}
    ] 
    assert_equal expected, @gdx.symbol(:AGG_OUT)
  end

  def test_missing_symbol
	assert_equal [], @gdx.symbol(:SYMBOL_THAT_DOES_NOT_EXIST)
  end

end
