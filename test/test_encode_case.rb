require 'minitest/autorun'
require_relative '../lib/encode_case'

class TestEncodeCase < MiniTest::Test
  include EncodeCase
  
  def test_encode_and_decode
    tests = {
    [[0,0,0],[1,1,1]] => 0,
    [[0,0,0],[2,2,2]] => 0,
    [[0,0,1],[2,2,2]] => 1,
    [[0,1,0],[2,2,2]] => 2,
    [[0,1,1],[2,2,2]] => 3,
    [[1,0,0],[2,2,2]] => 4,
    [[1,0,1],[2,2,2]] => 5,
    [[1,1,0],[2,2,2]] => 6,
    [[1,1,1],[2,2,2]] => 7,
    [[0,1,1],[2,3,2]] => 3,
    [[0,2,0],[2,3,2]] => 4,
    [[0,2,1],[2,3,2]] => 5,
    [[0,2,1,9,110,3,0,10],[1,12,3,10,999,3,1,20]] => 20068202,
  }
    
    tests.each do |from, to|
      assert_equal to, encode(from[0], from[1])
      assert_equal from[0], decode(to, from[1])
    end 
  end
  
end