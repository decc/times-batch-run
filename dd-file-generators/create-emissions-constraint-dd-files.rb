# This program is used to generate a range of emissions constraints
# relating to CB4, CB5 and the 2050 target, each in a separate dd file.
#
# Written by Tom Counsell tom@counsell.org
#
# To use:
# ruby create-cb5-emissions-constraint-dd-files.rb <target_directory>
#
# FIXME: What about CB1 and CB2?
require 'erb'

class CreateGHGConstraintFiles

	attr_accessor :target_directory

	def initialize(target_directory)
		@target_directory = target_directory
	end

  def template
     @template ||= ERB.new(IO.readlines(File.join(File.dirname(__FILE__), "ghg-target.dd" )).join)
  end
  
  def dd_file_for_emissions(scenario_name, year_emissions)
    template.result(binding)
  end

	def write(scenario_name, ghg)
		dd_file = dd_file_for_emissions(scenario_name, ghg)
		# Write the generated dd file to disk
		File.open(File.join(target_directory, scenario_name+".dd"), 'w') do |f|
			f.puts dd_file
		end
	end

	def go!
		create_cb3_files
		create_cb4_files
		create_cb5_files
		create_2050_target_files
	end
	
	# FIXME: This is NONSENSE until we get the EU ETS / Non ETS Split working
	def create_cb3_files
		write "cb3-hit", { 2020 => (2544*1000/5)} # ktCO2e Source 2014 Emisssions Projections Table 2.1
		write "cb3-beat", { 2020 => (2464*1000/5)} # ktCO2e Source 2014 Emisssions Projections Table 2.1
	end
	
	# FIXME: This is NONSENSE until we get the EU ETS / Non ETS Split working
	def create_cb4_files
		write "cb4-hit", { 2025 => (1950*1000/5)} # ktCO2e Source 2014 Emisssions Projections Table 2.1
		write "cb4-missed", {2025 => (2083*1000/5)} # ktCO2e Source 2014 Emisssions Projections Table 2.1
	end
	
	def create_cb5_files
		(1000..3000).step(100) do |cb5|
			write "cb5-#{cb5}", { 2030 => ((cb5*1000)/5.0) }
		end
	end
	
	def create_2050_target_files
		write "2050-target-hit", { 
			0 => 5, # This switches on linear interpolation and extrapolation, so TIMES will automatically add constraints for 2035-2045
			2050 => 160000 # This is ROUGHLY the 2050 target in ktCO2e
		}
		
		write "2050-target-abandoned", {
			0 => 1, # This allows interpolation, but doesn't allow extrapolation
			# Don't constrain 2050
		}
	end
end

if __FILE__ == $0
	create_ghg_constraint_files = CreateGHGConstraintFiles.new(ARGV[0] || '.')
	create_ghg_constraint_files.go!
end