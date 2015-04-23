require 'minitest/autorun'
require_relative '../lib/gdx'

$this_directory = File.dirname(__FILE__)

class TestGDX < MiniTest::Test

  def setup
    @gdx = Gdx.new(File.join($this_directory, 'test.gdx'))
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
