require_relative 'monte_carlo'

class Sensitivities < MonteCarlo

  def create_list_of_cases
    base_scenario_indexes = number_of_scenarios_per_set.map { 0 }
    add(base_scenario_indexes)
    
    number_of_scenarios_per_set.each.with_index do |n, row|
      next if n < 2
      (1...n).each do |i|
        this_scenario_indexes = base_scenario_indexes.dup
        this_scenario_indexes[row] = i
        add(this_scenario_indexes)
      end
    end
  end

  def number_of_sensitivites
    number_of_scenarios_per_set.inject(0) do |count, number|
      number > 1 ? count + number - 1 : count
    end + 1
  end
  
  def print_intent
    puts "Generating #{number_of_sensitivites} senstivitities from #{File.expand_path(file_containing_possible_combinations_of_scenarios)} and putting them in #{File.expand_path(name_of_list_of_cases)}"
  end

end
