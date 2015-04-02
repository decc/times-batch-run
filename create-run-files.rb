# create_run_files.rb
#
# This takes a list of cases and creates the run files that GAMS needs to 
# use to execute them.
#
# Usage:
# ruby create_run_files.rb <destination_folder_for_run_files> <name_of_file_containing_cases>
#
# Where:
# destination_folder_for_run_files - optional, default this folder, each row in the list of cases will become a run file in that folder
# name_of_file_containing_cases    - optional, default cases.tsv, list of each case, where the first column is the name of the case, and remaining columns are
#                                    scenarios to use in this case.
#
destination_folder_for_run_files  = ARGV[0] || '.'
name_of_file_containing_cases = ARGV[1] || 'cases.tsv'

puts "Taking cases from #{File.expand_path(name_of_file_containing_cases)} and creating run files in #{File.expand_path(destination_folder_for_run_files)}"

list_of_cases = IO.readlines(name_of_file_containing_cases).join.split(/[\n\r]+/).map { |r| r.split("\t") }
list_of_cases.shift # Remove the title row

list_of_cases.each do |c|

  run_filename = File.expand_path(File.join(destination_folder_for_run_files, "#{c.first}.RUN"))

  puts "Generating #{run_filename}"

  File.open(run_filename, 'w') do |f|
f.puts <<END
$ SET TIMESED NO
$ SET STAGES NO
$SET SOLVEDA 'YES'

* merge declarations & data
$   ONMULTI

* the times-slices MUST come 1st to ensure ordering OK
$BATINCLUDE uktm_base_ts.dd
 

* perform fixed declarations
$SET BOTIME 1970
$BATINCLUDE initsys.mod

* declare the (system/user) empties
$   BATINCLUDE initmty.mod
*$   BATINCLUDE initmty.mod DSC
$IF NOT DECLARED REG_BNDCST $Abort "You need to use TIMES v2.3.1 or higher"

#{ 
c[1..-1].map do |dd| 
  if dd == "NIL"
    ""
  else
    "$BATINCLUDE #{dd}.dd" 
  end
end.join("\n") 
}

SET MILESTONYR /2010,2011,2012,2015,2020,2025,2030,2035,2040,2045,2050,2055,2060/;
$SET RUN_NAME 'UKTM_BASE'


$ SET VEDAVDD 'YES'

* do the rest
$ BATINCLUDE maindrv.mod mod
END

  end
end
