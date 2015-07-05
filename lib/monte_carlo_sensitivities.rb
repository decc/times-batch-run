require_relative 'sensitivities'

class MonteCarloSensitivities < Sensitivities

  def create_list_of_cases
    number_of_scenarios_per_set.each.with_index do |n, row|
      next if n < 2
      number_of_monte_carlo_runs_per_sensitivity.times do 
        base_scenario_indexes = random_set_of_scenario_indexes
        (0...n).each do |i|
          this_scenario_indexes = base_scenario_indexes.dup
          this_scenario_indexes[row] = i
          add(this_scenario_indexes)
        end
      end
    end
  end

  def number_of_sensitivites
    number_of_scenarios_per_set.inject(0) do |count, number|
      number > 1 ? count + number - 1 : count
    end + 1
  end

  def number_of_monte_carlo_runs_per_sensitivity
    (number_of_cases_to_generate / number_of_sensitivites.to_f).ceil
  end

  def number_of_cases
    number_of_monte_carlo_runs_per_sensitivity * number_of_sensitivites
  end
  
  def print_intent
    puts "Generating #{number_of_sensitivites} senstivitities for #{number_of_monte_carlo_runs_per_sensitivity} monte carlo'd baselines (total: #{number_of_cases} cases against a target of #{number_of_cases_to_generate}) from #{File.expand_path(file_containing_possible_combinations_of_scenarios)} and putting them in #{File.expand_path(name_of_list_of_cases)}"
  end

end
