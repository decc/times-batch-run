# This program is used to generate a range of non-traded-sector constraints
# for a given level of CB4, CB5, EU ETS scenario and 2050 target, each in a separate dd file.
#
# Written by Tom Counsell tom@counsell.org
#
require 'erb'
require_relative '../lib/array_extensions'

class CreateNonTradedSectorConstraints

	attr_accessor :target_directory
  
	def initialize(target_directory)
		@target_directory = target_directory
	end
  
	def go!
    create_non_traded_scenarios
	end
  
  def create_non_traded_scenarios
    carbon_budget_scenarios.each do |carbon_budget_period, scenarios_for_that_budget|
      scenarios_for_that_budget.each do |carbon_budget_scenario, carbon_budget_level|
        ets_scenarios.keys.each do |ets_scenario|
          
          # Work out the non traded budget levels by subtracting off the ETS levels
          non_traded_budget_levels = carbon_budget_level.map do |year_emissions_budget|
            year, emissions = *year_emissions_budget
            [year, non_ets_value(year, emissions, ets_scenario)]
          end
          
          # Give it a handy name
          scenario_name = "#{carbon_budget_period}-#{carbon_budget_scenario}-ets-#{ets_scenario}"
          
          # Now write out the values
          write scenario_name, non_traded_budget_levels
        end
      end
    end
  end
  
  def carbon_budget_scenarios
    return @carbon_budget_scenarios if @carbon_budget_scenarios
    # These are all total carbon budget levels
    # Source 2014 Emisssions Projections Table 2.1
    @carbon_budget_scenarios = {
      "cb1" => {
        "budget" => [[2010, (3018/5) ]],
        "actual" => [[2010, (2982/5) ]],
      },
      "cb2" => {
        "budget" =>   [[2015, (2782/5) ]],
        "forecast" => [[2015, (2706/5) ]],
      },
      "cb3" => {
        "budget" =>   [[2020, (2544/5) ]],
        "forecast" => [[2020, (2464/5) ]],
      },
      "cb4" => {
        "budget" =>   [[2025, (1950/5) ]],
        "forecast" => [[2025, (2083/5) ]],
      }, 
      "cb5" => {}, # Populated lower down
      "2050" => {
        "target-hit" => [
          [0, 5], # Switches on interpolation
          [2050, 160]
        ],
        "target-missed" => [
          [0, 1], # This allows interpolation, but doesn't allow extrapolation
        ],        
      }
    }
    (1000..3000).step(100) do |cb5|
      @carbon_budget_scenarios["cb5"][cb5] = [[2030, cb5/5]]
    end
    @carbon_budget_scenarios
	end
    
  def ets_scenarios
    { # MtCO2e, will linearly interpolate for missing values
      "high" => [ # Currently made up
        [2010, 1227/5],
        [2015, 1078/5],
        [2020, 985/5],
        [2030, 690/5],
        [2050, 130],
        [2060, 100]
      ],
      "central" => [ # Currently made up
        [2010, 1227/5],
        [2015, 1078/5],
        [2020, 985/5],
        [2030, 690/5],
        [2050, 170],
        [2060, 50 ]      
      ],
      "low" => [ # Currently made up
        [2010, 1227/5],
        [2015, 1078/5],
        [2020, 985/5],
        [2030, 690/5],
        [2050, 0],
        [2060, 0]    
      ]
    }
  end
	
  def ets_value(year, scenario = "central")
    ets_scenarios[scenario].extend(InterpolateArrayExtension).interpolate(year)
  end
  
  def non_ets_value(year, total_emissions, ets_scenario)
    return total_emissions if year == 0 # A zero year is used by TIMES to pass interpolation settings
    total_emissions - ets_value(year, ets_scenario)
  end
  
  def template
     @template ||= ERB.new(IO.readlines(File.join(File.dirname(__FILE__), "non-ets_target.dd" )).join)
  end
  
  def emissions_constraint(year, emissions)
    return emissions if year == 0 # A zero year is used by TIMES to pass interpolation settings
    emissions * 1000 # Our data is in MtCO2e, UK TIMES works in ktCO2e
  end
  
  def dd_file_for_emissions(scenario_name, year_emissions)
    template.result(binding) # NB: The template converts to ktCO2e
  end

	def write(scenario_name, year_emissions)
		# Write the generated dd file to disk
		File.open(File.join(target_directory, scenario_name+".dd"), 'w') do |f|
			f.puts dd_file_for_emissions(scenario_name, year_emissions)
		end
	end



end

if __FILE__ == $0
	create_constraint_files = CreateNonTradedSectorConstraints.new(ARGV[0] || '.')
	create_constraint_files.go!
end