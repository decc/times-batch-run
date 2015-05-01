module EncodeCase
  # This class takes an array of integers: [0,1,1,3,5,4,9]
  # and an array of the number of options allowed in each position [1,2,2,4,6,5,10]
  # and encodes it into the smallest possible number
  def encode(values, maximums)
    # We create binary versions of each value, padding with zeros so could store the maximum
    # then join those binary strings together
    # and turn into a number
    values.map.with_index do |value, index|
      maximum = maximums[index]
      if maximum == 1
        nil # No point storing a value that only has a single option
      else
        value.to_s(2).rjust((maximum-1).to_s(2).length,'0')
      end
    end.compact.join('').to_i(2)
  end

  # This class takes a number (3865)
  # and an array of maximum values [0,1,1,3,5,4,9]
  # and decodes it into an array of integers: [0,1,1,3,5,4,9]
  def decode(number, maximums)
    # We create a binary version of the number
    # then split it into smaller binary numbers of the right size, given the maximum
    # then turn these binary numbers into actual numbers for the value array
    required_binary_length = maximums.inject(0) { |sum, maximum| maximum == 1 ? sum : sum + (maximum-1).to_s(2).length }
    binary = number.to_s(2).rjust(required_binary_length,"0")
    result = []
    index = 0
    maximums.each do |maximum|
      if maximum == 1
        result << 0 # It won't have been encoded, because only a single possible value
      else
        length_of_this_value = (maximum-1).to_s(2).length
        binary_for_this_value = binary.slice(index,length_of_this_value)
        result << binary_for_this_value.to_i(2)
        index += length_of_this_value
      end
    end
    result
  end
  
end