require 'csv'

GDXCache = {}

class Gdx
  attr_accessor :gdx_filename

  def initialize(gdx_filename)
    GDXCache[gdx_filename] ||= {}
    @gdx_filename = gdx_filename
  end

  def valid?
    return false unless File.exist?(gdx_filename)
    `gdxdump #{gdx_filename} Symb=ObjZ` =~ /free\s+Variable OBJZ/i ? true : false
  end

  def objz
    output = `gdxdump #{gdx_filename} Symb=ObjZ`
    output[/([0-9.]+)/,1].to_f
  end

  def symbol(symbol)
    result = get_symbol_from_cache(symbol)
    return result if result
    result = get_symbol_from_gdx(symbol)
    set_symbol_in_cache(symbol, result)
    result
  end

  def get_symbol_from_gdx(symbol)
    csv = `gdxdump #{gdx_filename} Symb=#{symbol} Format=csv`
    csv.gsub!(/,Eps\b/,',0.0') # \b matches word boundry. We are expecting comma or newline
    CSV.new(csv, headers: :true, converters: :all, header_converters: :symbol).to_a.map(&:to_hash)
  end

  def get_symbol_from_cache(symbol)
    GDXCache[gdx_filename][symbol]
  end

  def set_symbol_in_cache(symbol, result)
    GDXCache[gdx_filename][symbol] = result
  end

  def marginals(symbol)
    direct(symbol).select { |r| r[:type] =~ /m/i }
  end

  def raw(symbol)
    `gdxdump #{gdx_filename} Symb=#{symbol}`
  end

  def direct(symbol)
    raw_version = raw(symbol)
    return [] if raw_version =~ /^Symbol not found/i
    headers = extract_headers(raw_version)
    extract_rows(raw_version).map do |row|
      h = {}
      row[0..-2].each.with_index do |set, i|
        h[headers[i]] = set
      end
      h[:val] = row.last
      h
    end
  end

  def extract_headers(raw_gams)
    list_of_sets = raw_gams[/\((.*?)\)/,1]
    sets = list_of_sets.split(',').map(&:downcase).map(&:to_sym).push(:type)
  end

  def extract_rows(raw_gams)
    row_text = raw_gams[/\/(.*?)\//m,1]
    raw_rows = row_text.split(",").map(&:strip)
    rows = raw_rows.map do |row|
      sets, value = *row.split(" ")
      sets = *sets.split(".")
      type = sets.last =~ /^(lo|up|l|m)$/i ? sets.pop : "l"
      sets = sets.map { |s| s[/'(.*?)'/,1]}
      sets = sets.map { |s| try_to_convert_to_number(s) }
      value = 0 if value =~ /eps/i
      value = value.to_f
      sets.push(type).push(value)
    end
  end

  def try_to_convert_to_number(text)
    case text
    when /^\d+$/
      text.to_i
    when /^\d+\.\d+/
      text.to_f
    else
      text
    end
  end

  def scenarios
    scenario_list = symbol(:Scenarios).map { |hash| hash[:dim1] }
    scenario_list.push(used_dummy_values? ? "did_not_solve" : "solved")
    scenario_list
  end

  def used_dummy_values?
    var_act_text = raw(:VAR_ACT)
    var_act_text =~ /IMP...Z'\.'ANNUAL'\.L/im ? true : false
  end

  # This takes flat data and reshapes it into nested data
  # See the test test.gdx.rb for an example
  def reshape_cast(output, input, identifier:, attribute:, scenario:, keys:, values: [],  drop: [] )
    # Only some of the input data identifies the record
    if identifier.respond_to?(:call)
      id = identifier.call(input)
    else
      id = input.select { |k,v| identifier.include?(k) }
    end

    # If we are creating a new record
    unless output.has_key?(id)
      # Then only transfer some of the input data to that new record
      attributes_to_loose = [attribute].concat(keys).concat(values).concat(drop)
      output[id] = input.reject { |k,v| attributes_to_loose.include?(k) }
    end
    # This is the record that the data is to become
    target = output[id]
    # We are now adding the data to a new attribute in the record
    # the name of the attribute is governed by the value of the
    # original record's attribute
    attribute_value = input[attribute].to_sym
    unless target.has_key?(attribute_value)
      target[attribute_value] = []
    end
    # Within that attribute we allow multiple scenarios
    existing_scenarios = target[attribute_value]
    existing_scenario = existing_scenarios.find { |s| s[:name] == scenario }
    unless existing_scenario
      existing_scenario = { name: scenario, data: [] }
      existing_scenarios.push(existing_scenario)
    end
    existing_data = existing_scenario[:data]
    # Now we need to deal with duplicate bits of data, which we tend to sum
    new_key =  input.select { |k,v| keys.include?(k) }

    # Check if there is an existing piece of data that matches
    existing_datum = existing_data.find do |d|
      d.select { |k,v| keys.include?(k) } == new_key
    end

    # If there is, add the new values to the current values
    if existing_datum
      values.each do |v|
        existing_datum[v] += input[v]
      end
    else
      # Otherwise add a new piece of data
      new_datum = input.select { |k,v| keys.include?(k) || values.include?(k) }
      existing_data.push(new_datum)
    end
  end

end
