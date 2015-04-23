require_relative './gdx'

class ExtractDetailedCosts

  cst_UNIT = "£M"
  PROCESS_NAME_REGEX = /^(.*?)\d*$/ # This is used to trim the numbers off the end of process names
  YEARS = [2011, 2012, 2015, 2020, 2025, 2030, 2035, 2040, 2045, 2050, 2055, 2060] # The gdx data doesn't include zero values, so we have to include them manually. <sigh>
  COST_VARIABLES = [ # There doesn't appear to be a process by process aggregation, so we do it manually
    :cst_invc,
    :cst_invx,
    #:cst_salv, # Not sure how to deal with salvage costs yet
    :cst_decc,
    :cst_fixc,
    :cst_fixx,
    :cst_actc,
    :cst_floc,
    :cst_flox,
    :cst_comc,
    :cst_comx,
    :cst_come,
    :cst_dam,
    :cst_irec
  ]

  attr_accessor :scenario_name
  attr_accessor :gdx
  attr_accessor :discount_factors
  
  def extract_detailed_costs
    processes_by_year = Hash.new() { |hash, new_key| hash[new_key] = Hash.new(0) }
    results = { 
      :name => scenario_name,
      :processes_by_year => processes_by_year
    }
    COST_VARIABLES.each do |variable|
      gdx.symbol(variable.to_sym).each do |row|
        # {:r=>"UK", :allyear=>2012, :t=>2012, :p=>"RHNRAD01", :sysuc=>"INV", :val=>49.7921456424048}
        year = row[:t]
        process_name = combined_process_name(row[:p])
        value = row[:val]
        processes_by_year[process_name][year] += value
      end
    end
    processes_by_year.each do |process_name, year_values|
      # {2010 => 5, 2030 => 8}
      year_values["npv"] = npv(year_values)
    end
    results
  end
  
  # Strips the trailing 00 01 02 off the end of process names to group them a bit
  def combined_process_name(process_name)
    process_name[PROCESS_NAME_REGEX,1]
  end
  
  def npv(year_value_hash)
    result = 0
    year_value_hash.each do |year, value|
      result += value * discounted_sum_factors[year]
    end
    result
  end
  
  def discounted_sum(year_value_hash)
    result = {}
    year_value_hash.each do |year, value|
      result[year] = value * discounted_sum_factors[year]
    end
    result
  end
  
  def discounted_sum_factors
    @discounted_sum_factors ||= extract_discounted_sum_factors
  end
  
  def extract_discounted_sum_factors
    factors = {}
    gdx.symbol(:CST_TIME).each do |year|
      factors[year[:allyear]] = year[:val]
    end
    factors
  end
end
