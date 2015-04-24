require 'minitest/autorun'
require_relative '../lib/array_extensions'

class TestArrayExtensions < MiniTest::Test
  
  def setup
    @array = [
      [2010, 200],
      [2020, 400],
      [2040, 100],
    ]
    @array.extend(InterpolateArrayExtension)
  end
  
  def test_exact_value
    assert_equal(200, @array.interpolate(2010))
    assert_equal(400, @array.interpolate(2020))
    assert_equal(100, @array.interpolate(2040))
  end
  
  def test_between_values
    assert_equal(300, @array.interpolate(2015))
    assert_equal(250, @array.interpolate(2030))
  end
  
  def test_extrapolate_below_start
    assert_equal(100, @array.interpolate(2005))
    assert_equal(0  , @array.interpolate(2000))
    assert_equal(-50, @array.interpolate(1997.5))
  end
  
  def test_extrapolate_above_finish
    assert_equal(-50 , @array.interpolate(2050))
    assert_equal(-200, @array.interpolate(2060))
    assert_equal(-800, @array.interpolate(2100))
  end
  
end
  
