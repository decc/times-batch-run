require_relative 'gdx'

class ExtractBuildRates

  UNITS_FILENAME = File.join(File.dirname(__FILE__),'..','data', 'UnitsForEachProcess.csv')
  COST_UNIT = "£M"
  PROCESS_NAME_REGEX = /^(.*?)\d*$/ # This is used to trim the numbers off the end of process names
  YEARS = [2011, 2012, 2015, 2020, 2025, 2030, 2035, 2040, 2045, 2050, 2055, 2060] # The gdx data doesn't include zero values, so we have to include them manually. <sigh>

  attr_accessor :scenarios
  attr_accessor :scenario_name
  attr_accessor :gdx
  

  def extract_new_capacity_cost
    
    # We use this to remove the 00 and 01 from the end of the process names
    # and then merge the data
    identifier = lambda { |input| input[:p] = input[:p][PROCESS_NAME_REGEX,1] }

    reformatted_results = {}

    gdx.symbol(:CAP_NEW).each do |datum|
      gdx.reshape_cast(
        reformatted_results, 
        datum,
        identifier: identifier, # We identify the record by its process name
        attribute: :item, # We group data according to 'INSTCAP' and 'LUMPINV'
        scenario: scenario_name, # This is so we can compare two runs
        keys: [:allyear],  # This is the investment year
        values: [:val], # This is the quanitity
        drop: [ :r, :allyear_1 ] # We ignore region and vintage
      )
    end
    reformatted_results
  end

  def extract_new_capacity_cost_sorted
    results = extract_new_capacity_cost.values
    results.sort_by do |record|
      if record.has_key?(:LUMPINV)
        record[:LUMPINV].inject(0) do |sum, scenario|
          sum + scenario[:data].inject(0) do |total, d|
            total + d[:val]
          end
        end
      else
        0
      end
    end.reverse
  end

  def extract_new_capacity_with_cost_per_unit_sorted
    results = extract_new_capacity_cost_sorted
    adjust_values_to_reflect_length_of_period_covered_in results
    add_missing_zeros_to results
    add_cost_per_unit_to results
    add_max_values_to results
    add_units_to results
    results
  end

  def add_cost_per_unit_to(results)
    results.each do |process|
      total_cost = process[:LUMPINV]
      deployment = process[:INSTCAP]
      next unless total_cost && deployment
      cost_per_unit = process[:COSTPERUNIT] = [] 
      total_cost.each do |scenario|
        scenario_name = scenario[:name]
        cost_per_unit_data = []
        deployment_scenario = deployment.find { |s| s[:name] == scenario_name }
        next unless deployment_scenario
        deployment_data = deployment_scenario[:data]
        scenario[:data].each do |total_cost_datum|
          total_cost_key = total_cost_datum[:allyear]
          deployment_datum = deployment_data.find { |d| d[:allyear] == total_cost_key }
          next unless deployment_datum
          total_cost_value = total_cost_datum[:val]
          deployment_value = deployment_datum[:val]
          next if deployment_value == 0
          cost_per_unit_value = total_cost_value / deployment_value
          cost_per_unit_data.push({allyear: total_cost_key, val: cost_per_unit_value})
        end
        cost_per_unit.push({name: scenario_name, data: cost_per_unit_data})
      end
    end
    results
  end

  def max_value_in_attribute(data)
    return 0 unless data
    data.each do |scenario|
      max = 0
      scenario[:data].each do |d|
        max = d[:val] if d[:val] > max
      end
      scenario[:max] = max
    end
  end

  def add_max_values_to(results)
    results.each do |process|
      max_value_in_attribute(process[:INSTCAP])
      max_value_in_attribute(process[:COSTPERUNIT])
      max_value_in_attribute(process[:LUMPINV])
    end
    results
  end


  def add_units_to(results)
    results.each do |process|
      capacity_unit = units[process[:p]] || "Unknown unit"
      set_in_all_scenarios process[:INSTCAP], unit: capacity_unit
      set_in_all_scenarios process[:LUMPINV], unit: COST_UNIT
      set_in_all_scenarios process[:COSTPERUNIT], unit: COST_UNIT+"/"+capacity_unit
    end
  end

  def add_missing_zeros_to(results)
    results.each do |process|
      add_missing_zeros_to_attribute process[:INSTCAP]
      add_missing_zeros_to_attribute process[:LUMPINV]
    end
  end

  def add_missing_zeros_to_attribute(attribute) 
    return unless attribute
    attribute.each do |scenario|
      add_missing_zeros_to_data(scenario[:data])
    end
  end

  def add_missing_zeros_to_data(data)
    YEARS.each do |year|
      unless data.find { |d| d[:allyear] == year }
        data.push({:allyear=>year, :val => 0})
      end
    end
    data.sort! { |a,b| a[:allyear] <=> b[:allyear] }
    data
  end

  def set_in_all_scenarios(scenarios, hash)
    return unless scenarios
    scenarios.each do |scenario|
      scenario.merge!(hash)
    end
  end

  def adjust_values_to_reflect_length_of_period_covered_in(results)
    results.each do |process|
      adjust_values_to_reflect_length_of_period_in_attribute process[:INSTCAP]
      adjust_values_to_reflect_length_of_period_in_attribute process[:LUMPINV]
    end
  end

  def adjust_values_to_reflect_length_of_period_in_attribute(scenarios)
    return unless scenarios
    scenarios.each do |scenario|
      scenario[:data].each do |d|
        length_of_period = length_of_periods[d[:allyear]]
        d[:val] = d[:val]/length_of_period
      end
    end
  end

  def length_of_periods
    @length_of_periods ||= load_length_of_periods
  end

  def load_length_of_periods
    h = {}
    # FIXME: Assumes length of period same across gdx files
    gdx.symbol(:LEAD).each do |data|
      h[data[:allyear]] = data[:val]
    end
    h
  end

  def units
    @units ||= load_units
  end

  def load_units
    h = {}
    CSV.new(IO.readlines(UNITS_FILENAME).join, headers: :true).each do |row|
      h[row["Process"][PROCESS_NAME_REGEX,1]] = row["CapUnit"]
    end
    h
  end
end
