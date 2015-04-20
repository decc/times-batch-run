require 'minitest/autorun'
require_relative '../lib/extract_investment'
require 'pp'

$this_directory = File.dirname(__FILE__)

class TestExtractInvestment < MiniTest::Test

  def setup
    @extract_investment = ExtractInvestment.new({ "ScenarioA" => File.join($this_directory, 'test.gdx')})
  end

  def test_new_capacity
    expected = {
      :p=>"INMHTHHCO", 
       :INSTCAP=> [{:name=>"ScenarioA", :data=>[
         {:allyear=>2011, :val=>0.105415604160742}, 
         {:allyear=>2012, :val=>0.195443542582625}, 
         {:allyear=>2015, :val=>0.751049572848854}, 
         {:allyear=>2020, :val=>2.33661591524252}, 
         {:allyear=>2025, :val=>3.59468862258873}, 
         {:allyear=>2030, :val=>4.92185660796663}, 
         {:allyear=>2035, :val=>0.10382768156934}, 
         {:allyear=>2040, :val=>0.830880844003039}, 
         {:allyear=>2045, :val=>1.9317685782643}, 
         {:allyear=>2050, :val=>2.99818295607331}, 
         {:allyear=>2055, :val=>4.92185660796663}, 
         {:allyear=>2060, :val=>0.10382768156934}]}], 
       :LUMPINV=>[{:name=>"ScenarioA", :data=>[
         {:allyear=>2011, :val=>0.707779510861624},
         {:allyear=>2012, :val=>1.31224343939879},
         {:allyear=>2015, :val=>5.04268323020965},
         {:allyear=>2020, :val=>15.688463607722},
         {:allyear=>2025, :val=>24.1353922434113},
         {:allyear=>2030, :val=>33.0462391241978},
         {:allyear=>2035, :val=>0.697117910200352},
         {:allyear=>2040, :val=>5.57868488289488},
         {:allyear=>2045, :val=>13.6372003507501},
         {:allyear=>2050, :val=>21.1654864460591},
         {:allyear=>2055, :val=>34.7455411666401},
         {:allyear=>2060, :val=>0.7329650722382}]
        }]
    }
    result = @extract_investment.extract_new_capacity_cost
    assert_equal expected, result.values[54]
  end

  def test_new_capacity_sorted
    expected = {:p=>"RECOMPUT", 
                :INSTCAP=>[{:name=>"ScenarioA", :data=>[
                  {:allyear=>2011, :val=>6.87306774737565},
                  {:allyear=>2012, :val=>6.87306774737591},
                  {:allyear=>2015, :val=>24.7430438905536},
                  {:allyear=>2020, :val=>37.6663169176437},
                  {:allyear=>2025, :val=>40.6628171058533},
                  {:allyear=>2030, :val=>43.2348046005034},
                  {:allyear=>2035, :val=>45.9694743720702},
                  {:allyear=>2040, :val=>48.8771163318688},
                  {:allyear=>2045, :val=>51.9686712443791},
                  {:allyear=>2050, :val=>55.255771894739},
                  {:allyear=>2055, :val=>55.255771894739},
                  {:allyear=>2060, :val=>55.255771894739}]}], 
                :LUMPINV=>[{:name=>"ScenarioA", :data=>[
                  {:allyear=>2011, :val=>53352.7597373083},
                  {:allyear=>2012, :val=>53352.7597373103},
                  {:allyear=>2015, :val=>192069.93505432},
                  {:allyear=>2020, :val=>292387.916220335},
                  {:allyear=>2025, :val=>315648.498026093},
                  {:allyear=>2030, :val=>335613.764758961},
                  {:allyear=>2035, :val=>356841.86618994},
                  {:allyear=>2040, :val=>379412.678610999},
                  {:allyear=>2045, :val=>407211.158843022},
                  {:allyear=>2050, :val=>432967.908688949},
                  {:allyear=>2055, :val=>432967.908688949},
                  {:allyear=>2060, :val=>432967.908688949}]}]}
    result = @extract_investment.extract_new_capacity_cost_sorted
    assert_equal expected, result.first
  end

  def test_new_capacity_with_cost_per_unit_sorted
    expected = {:p=>"RECOMPUT",
     :INSTCAP=>[{:name=>"ScenarioA", :data=>[
      {:allyear=>2011, :val=>6.87306774737565},
      {:allyear=>2012, :val=>6.87306774737591},
      {:allyear=>2015, :val=>8.2476812968512}, # Values reduce to reflect length of period
      {:allyear=>2020, :val=>7.533263383528739},
      {:allyear=>2025, :val=>8.13256342117066},
      {:allyear=>2030, :val=>8.64696092010068},
      {:allyear=>2035, :val=>9.19389487441404},
      {:allyear=>2040, :val=>9.77542326637376},
      {:allyear=>2045, :val=>10.39373424887582},
      {:allyear=>2050, :val=>11.0511543789478},
      {:allyear=>2055, :val=>11.0511543789478},
      {:allyear=>2060, :val=>11.0511543789478}], :max=>11.0511543789478, :unit=>"PJ_a"}], 
    :LUMPINV=>[{:name=>"ScenarioA", :data=>[
      {:allyear=>2011, :val=>53352.7597373083},
      {:allyear=>2012, :val=>53352.7597373103},
      {:allyear=>2015, :val=>64023.31168477333},
      {:allyear=>2020, :val=>58477.583244067},
      {:allyear=>2025, :val=>63129.6996052186},
      {:allyear=>2030, :val=>67122.7529517922},
      {:allyear=>2035, :val=>71368.37323798801},
      {:allyear=>2040, :val=>75882.5357221998},
      {:allyear=>2045, :val=>81442.2317686044},
      {:allyear=>2050, :val=>86593.5817377898},
      {:allyear=>2055, :val=>86593.5817377898},
      {:allyear=>2060, :val=>86593.5817377898}], :max=>86593.5817377898, :unit=>"£M"}], 
    :COSTPERUNIT=>[{:name=>"ScenarioA", :data=>[
      {:allyear=>2011, :val=>7762.583128571668},
      {:allyear=>2012, :val=>7762.583128571665},
      {:allyear=>2015, :val=>7762.583128571682},
      {:allyear=>2020, :val=>7762.5831285716795},
      {:allyear=>2025, :val=>7762.583128571686},
      {:allyear=>2030, :val=>7762.58312857168},
      {:allyear=>2035, :val=>7762.583128571673},
      {:allyear=>2040, :val=>7762.583128571658},
      {:allyear=>2045, :val=>7835.704648443666},
      {:allyear=>2050, :val=>7835.704648443662},
      {:allyear=>2055, :val=>7835.704648443662},
      {:allyear=>2060, :val=>7835.704648443662}], :max=>7835.704648443666, :unit=>"£M/PJ_a"}]}
    result = @extract_investment.extract_new_capacity_with_cost_per_unit_sorted
    assert_equal expected, result.first

  end

  def test_units
    assert_equal "M-Units_a", @extract_investment.units["RELITLED"]
  end

  def test_length_of_periods
    expected = {2010=>1, 2011=>1, 2012=>1, 2015=>3, 2020=>5, 2025=>5, 2030=>5, 2035=>5, 2040=>5, 2045=>5, 2050=>5, 2055=>5, 2060=>5} 
    assert_equal expected, @extract_investment.length_of_periods

  end

end

