# This program is used to generate a sweep of CB5
# emisions constraints, from 3000 MtCO2e/budget to 1000 MtCO2e/budget
# each in a separate dd file. It constrains emissions to go from the
# selected CB5 level to the 2050 target linearly
#
# Written by Tom Counsell tom@counsell.org
#
# To use:
# ruby create-cb5-emissions-constraint-dd-files.rb <target_directory> <first_part_of_dd_filename>
#
# target_directory - optional, but should be the place where dd files are saved. A good spot is VEDA_FE/GAMS_WrkTIMES, default is this directory
# first_part_of_dd_filename - optional, default is ghg_constraint_including_2050_linear_cb5_is_, which results in a series of dd files like this:
#   ghg_constraint_including_2050_linear_cb5_is_1000.dd
#   ghg_constraint_including_2050_linear_cb5_is_1100.dd
#   ghg_constraint_including_2050_linear_cb5_is_1200.dd
#   ...
#   ghg_constraint_including_2050_linear_cb5_is_2900.dd
#   ghg_constraint_including_2050_linear_cb5_is_3000.dd

target_directory = ARGV[0] || '.'
first_part_of_dd_filename = ARGV[1] || "ghg_constraint_including_2050_linear_cb5_is_"

(1000..3000).step(100) do |cb5|
  scenario_name = "#{first_part_of_dd_filename}#{cb5}"
  ghg = {}
  ghg[2015] = 596800 # Keep CB1-4 the same
  ghg[2020] = 549200
  ghg[2025] = 430000
  ghg[2030] = (cb5/5)*1000 # Sweep through different choices for 2030, based on CB5 levels
  ghg[2050] = 159588 # Always hit the target

  # Linearly interpolate the years between 2030 and 2050
  delta_year = 2050-2030
  delta_ghg = (ghg[2050]-ghg[2030])/delta_year

  [2035, 2040, 2045].each do |interpolated_year|
    ghg[interpolated_year] = ghg[2030]+(delta_ghg*(interpolated_year-2030))
  end

dd_file = <<END
$ONEMPTY
$ONEPS
$ONWARNING
$SET SCENARIO_NAME '#{scenario_name}'
SET TOP_IRE
/
/

SET UC_N
/
/

PARAMETER
COM_BNDNET ' '/
#{
ghg.map do |year, limit|
  "UK.#{year}.GHGTOT.ANNUAL.UP #{limit}"
end.join("\n")
}
/
END

  # Write the generated dd file to disk
  File.open(File.join(target_directory, scenario_name+".dd"), 'w') do |f|
    puts dd_file
    f.puts dd_file
  end

end
