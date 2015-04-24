module InterpolateArrayExtension
  # Assumes the array is a set of 
  # sorted two element sub arrays:
  # [
  # [2010, 200],
  # [2020, 100],
  # [2030, 100]
  # ]
  def interpolate(lookup_value)
    return nil if empty?
    i = 0
    return extrapolate_below_start(lookup_value) if first.first > lookup_value
    while i < length
      return at(i).last if at(i).first == lookup_value
      return interpolate_between_values(lookup_value, i-1, i) if at(i).first > lookup_value
      i += 1
    end
    extrapolate_above_finish(lookup_value)
  end
  
  def extrapolate_below_start(lookup_value)
    return first.last if length == 1 # Can't really extrapolate if a single value
    interpolate_between_values(lookup_value, 0, 1)
  end
  
  def interpolate_between_values(lookup_value, from_index, to_index)
    from_key, from_value = *at(from_index)
    to_key  , to_value   = *at(to_index)
    key_difference = (to_key - from_key).to_f
    value_difference = (to_value - from_value).to_f

    (((lookup_value - from_key)/key_difference) * value_difference) + from_value
  end
  
  def extrapolate_above_finish(lookup_value)
    return first.last if length == 1 # Can't really extrapolate if a single value
    interpolate_between_values(lookup_value, -2, -1)
  end
end