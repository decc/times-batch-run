# This updates the index.txt file to match the folders in this directory
# Case directories are the ones with json in them
case_directories = Dir['*/*.json']
case_names = case_directories.map { |f| File.basename(File.dirname(f)) }
unique_case_names = case_names.uniq
File.open("index.txt", 'w') { |f| f.puts unique_case_names.join("\n") }
