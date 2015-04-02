# run-cases.rb
# 
# Executes TIMES on a series of cases, making the results available to VEDA
#
# The series of cases are expected to be named like this:
# case1.RUN
# case2.RUN
# ...
# case100.RUN
#
# Should be executed in the veda_fe folder
#
# Usage:
# ruby run-cases.rb <veda_fe_folder> <prefix> <start_number> <end_number> 
#
# Where:
# veda_fe_folder - optional, default '.', The VEDA Front End (FE) folder
# prefix         - optional, default 'cases', the prefix of the RUN filename
# start_number   - optional, default 1, the first number to add to the RUN filename
# end_number     - optional, default unset, the last number to add to the RUN filename
#                 if not set, then will keep going until it can't find a RUN file with 
#                 the right number

veda_fe_folder = File.expand_path(ARGV[0] || '.')
prefix = ARGV[1] || 'cases'
start_number = (ARGV[2] && ARGV[2].to_i) || 1
end_number = (ARGV[3] && ARGV[3].to_i)

times_source_folder = File.join(veda_fe_folder, "GAMS_SRCTIMESV380")
gams_working_folder =  File.join(veda_fe_folder, "GAMS_WrkTIMES")
gdx_save_folder =  File.join(gams_working_folder, "GamsSave")
vt_gams = File.join(times_source_folder, "VT_GAMS.CMD")
times_2_veda = File.join(times_source_folder, "times2veda.vdd") 

puts "Moving into VEDA FE folder #{veda_fe_folder}"

unless File.exist?(times_source_folder)
  puts "Can't find TIMES source folder: #{times_source_folder}"
  exit
end

unless File.exist?(gams_working_folder)
  puts "Can't find GAMS working folder: #{gams_working_folder}"
  exit
end

unless File.exist?(gdx_save_folder)
  puts "Can't find GDX save folder: #{gdx_save_folder}"
  exit
end

unless File.exist?(vt_gams)
  puts "Can't find VT_GAMS script: #{vt_gams}"
  exit
end

unless File.exist?(times_2_veda)
  puts "Can't find times2veda.vdd script: #{times_2_veda}"
  exit
end

Dir.chdir(gams_working_folder) # Move into the working folder

i = start_number

puts "Starting at #{start_number}"

loop do
  case_name = "#{prefix}#{i}"
  puts "Looking for #{case_name}.RUN"
  unless File.exist?("#{case_name}.RUN")
    puts "Can't find #{File.expand_path("#{case_name}.RUN")}"
    puts "Halting"
    exit
  end
  puts "Executing #{case_name}"
  puts `#{vt_gams} #{case_name} GAMS_SRCTIMESV380 #{File.join(gdx_save_folder, case_name)}`

  puts "Putting #{case_name} into VEDA"
  puts `GDX2VEDA #{File.join(gdx_save_folder, case_name)} #{times_2_veda} #{case_name}`
  i = i + 1
  if i > end_number
    puts "Done case #{end_number}"
    puts "Halting"
    exit
  end
end



