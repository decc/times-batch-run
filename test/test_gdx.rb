require 'minitest/autorun'
require_relative '../lib/gdx'

$this_directory = File.dirname(__FILE__)

class TestGdx < MiniTest::Test

  def setup
    @gdx = Gdx.new(File.join($this_directory, 'test.gdx'))
  end

  def test_valid
    assert @gdx.valid?
    refute Gdx.new(__FILE__).valid?
    refute Gdx.new(File.join($this_directory, "file_that_does_not_exist")).valid?
  end

  def test_objective_function_cost
    expected = 10121626.581776 # Quantity, a cost, probably £M (i.e., £10trn in this case)
      # Plausability check: £10trn / 50 years = £200 billion a year, and we spend about £100 billion on fuel
      # £10trn needs adjusting up for discounting (doubling?)
      # £100bn needs the cost of equipement (especially cars adding on)
    assert_equal expected, @gdx.objz
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

  def test_new_capacity_quantity
    expected =  {
      :r=>"UK", # Region (always UK)
      :allyear=>2010, # Year new capacity added? What about the lead time?
      :p=>"IISFINPRO00", # Process
      :val=>9.34956777777778 # Quantity, but how do I find out what unit?
    }
    assert_equal expected, @gdx.symbol(:VAR_NCAP).first
  end

  def test_new_capacity_unit_cost
    expected =  nil # Why doesn't it dump this?
    assert_equal expected, @gdx.symbol(:NCAP_COST).first
  end

  def test_new_capacity_unit_cost_new_gdx
    expected =  nil # Why doesn't it dump this?
    assert_equal expected, @gdx.symbol(:NCAP_COST).first
  end

  def test_scenarios_from_old_gdx_format
    expected = []
    assert_equal expected, @gdx.scenarios
  end

  def test_scenarios_from_new_gdx_format
    new_gdx = Gdx.new(File.join($this_directory, 'test3.gdx'))
    expected = ["base", "newagr", "newelc", "newind", "newprc", "newres", "newrsr", "newser", "newtra", "refscenario", "syssettings", "uc_base", "uc_elc", "uc_ind", "uc_prc", "uc_res", "uc_rsr", "uc_ser", "uc_tra", "discount_stern", "cb3-beat", "cb4-missed", "cb5-3000", "2050-target-hit", "re_target"]
    assert_equal expected, new_gdx.scenarios
  end

  def test_new_capacity_unit
    expected =  nil # Why doesn't it dump this?
    assert_equal expected, @gdx.symbol(:PRC_CAPUNT).first
  end

  def test_new_capacity_cost
    expected =  {
      :r=>"UK", # Region, always the same
      :allyear=>2010,  # Year of investment
      :p=>"IISFINPRO00", # Process
      :allyear_1=>2010,  # Vintage, normally the same as the investment year
      :item=>"INSTCAP",  # ? Can be INSTCAP or LUMPINV.
      :val=>9.34956777777778, # When :item is INSTCAP, this is the same as :VAR_NCAP?
    }
    assert_equal expected, @gdx.symbol(:CAP_NEW).first
  end

  def test_period_lengths
    expected = {:allyear=>2010, :val=>1}, {:allyear=>2011, :val=>1}, {:allyear=>2012, :val=>1}, {:allyear=>2015, :val=>3}, {:allyear=>2020, :val=>5}, {:allyear=>2025, :val=>5}, {:allyear=>2030, :val=>5}, {:allyear=>2035, :val=>5}, {:allyear=>2040, :val=>5}, {:allyear=>2045, :val=>5}, {:allyear=>2050, :val=>5}, {:allyear=>2055, :val=>5}, {:allyear=>2060, :val=>5}
    assert_equal expected, @gdx.symbol(:LEAD)
  end

  # Sometimes the gdx data returns EPS when we want it to give a zero
  def test_eps
    assert_equal 0.0, @gdx.symbol(:CAP_NEW)[3101][:val]
  end

  # We use this method to group the data into a new format
  def test_reshape_cast
    data =  [
    {
      :r=>"UK", # Region, always the same
      :allyear=>2010,  # Year of investment
      :p=>"IISFINPRO00", # Process
      :allyear_1=>2010,  # Vintage, normally the same as the investment year
      :item=>"INSTCAP",  # ? Can be INSTCAP or LUMPINV.
      :val=> 100, # When :item is INSTCAP, this is the same as :VAR_NCAP?
    },
    {
      :r=>"UK", # Region, always the same
      :allyear=>2020,  # Year of investment
      :p=>"IISFINPRO00", # Process
      :allyear_1=>2020,  # Vintage, normally the same as the investment year
      :item=>"INSTCAP",  # ? Can be INSTCAP or LUMPINV.
      :val=> 200, # When :item is INSTCAP, this is the same as :VAR_NCAP?
    }
    ]
    expected = {
      {:p=> "IISFINPRO00"} => {
        :r=>"UK", # Region, always the same
        :p=>"IISFINPRO00", # Process
        :INSTCAP => [
          { name: 'ScenarioA', data: [
            { :allyear => 2010, :val => 100},
            { :allyear => 2020, :val => 200}]
          }
        ]
      }
    }
    result = {}
    @gdx.reshape_cast(result, data[0], identifier: [:p], attribute: :item, scenario: 'ScenarioA', keys: [:allyear, :val], drop: [ :allyear_1 ])
    @gdx.reshape_cast(result, data[1], identifier: [:p], attribute: :item, scenario: 'ScenarioA', keys: [:allyear, :val], drop: [ :allyear_1 ])

    assert_equal expected, result
  end

  def test_reshape_cast_with_sum
    data =  [
    {
      :r=>"UK", # Region, always the same
      :allyear=>2010,  # Year of investment
      :p=>"IISFINPRO00", # Process
      :allyear_1=>2010,  # Vintage, normally the same as the investment year
      :item=>"INSTCAP",  # ? Can be INSTCAP or LUMPINV.
      :val=> 100, # When :item is INSTCAP, this is the same as :VAR_NCAP?
    },
    {
      :r=>"UK", # Region, always the same
      :allyear=>2010,  # Year of investment
      :p=>"IISFINPRO00", # Process
      :allyear_1=>2020,  # Vintage, normally the same as the investment year
      :item=>"INSTCAP",  # ? Can be INSTCAP or LUMPINV.
      :val=> 200, # When :item is INSTCAP, this is the same as :VAR_NCAP?
    }
    ]
    expected = {
      {:p=> "IISFINPRO00"} => {
        :r=>"UK", # Region, always the same
        :p=>"IISFINPRO00", # Process
        :INSTCAP => [
          { name: 'ScenarioA', data: [
            { :allyear => 2010, :val => 300},
          ]}
        ]
      }
    }
    result = {}
    @gdx.reshape_cast(result, data[0], identifier: [:p], attribute: :item, scenario: 'ScenarioA', keys: [:allyear], values: [:val], drop: [ :allyear_1 ])
    @gdx.reshape_cast(result, data[1], identifier: [:p], attribute: :item, scenario: 'ScenarioA', keys: [:allyear], values: [:val], drop: [ :allyear_1 ])

    assert_equal expected, result
  end

  def test_reshape_cast_with_stemmed_identifier
    data =  [
    {
      :allyear=>2010,
      :p=>"IISFINPRO00", # Process ends in 00
      :item=>"INSTCAP",
      :val=> 100,
    },
    {
      :allyear=>2020,
      :p=>"IISFINPRO01", # Process ends in 01
      :item=>"INSTCAP",
      :val=> 200,
    }
    ]
    expected = {
      "IISFINPRO" => { # Process has been stemmed
        :p=>"IISFINPRO", # Process has been stemmed
        :INSTCAP => [
          { name: 'ScenarioA', data: [
            { :allyear => 2010, :val => 100}, # Data has been merged
            { :allyear => 2020, :val => 200}]
          }
        ]
      }
    }
    result = {}
    identifier = lambda { |input| input[:p] = input[:p][/^(.*?)\d*$/,1] }
    @gdx.reshape_cast(result, data[0], identifier: identifier, attribute: :item, scenario: 'ScenarioA', keys: [:allyear], values: [:val], drop: [ :allyear_1 ])
    @gdx.reshape_cast(result, data[1], identifier: identifier, attribute: :item, scenario: 'ScenarioA', keys: [:allyear], values: [:val], drop: [ :allyear_1 ])

    assert_equal expected, result
  end



end
