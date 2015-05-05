#2015-05-05

* The build rate chart by default only shows the top 10 costs

#2015-05-04

* Fixed the gdx validity test to be less case sensitive
* Fixed objective function value extraction to work in new version of GAMS
* Fixed results generation to work in go.rb even if skip the results creation

#2015-05-01

* go.rb can now cope with any sort of case name being specified in the cases.tsv - they don't need to be numbered
* Removed create-run-files.rb
* Removed run-cases.rb
* Renamed create-list-of-cases.rb to monte-carlo.rb
* go.rb only does a monte-carlo if the cases.tsv file is missing
* Altered the command line options for monte-carlo.rb run monte-carlo.rb --help for details
* monte-carlo'd cases now have a sequence of numbers and letters at the end that means that two cases with the same scenarios will have the same name
* Can now specify the list of cases file to go.rb (or more than one if you want)
* go.rb now includes ALL the results in index.txt
* go.rb can now limit processing to the first N cases with the -n switch
* go.rb can now specify the number of cases to optimize in parallel with -p switch

#2015-04-30

* The generated RUN files now include a preset set of time slices. Removes an otherwise unintelligable error.
* Now embeds the scenarios that have been used in a case into the GAMS code so that it appears and can be read from the gdx file
* Consolidated code for flying bricks into core
* Renamed ExtractInvestment to ExtractBuildRates
* Renamed flying-brick.html to detailed-costs.html
* Consolidated the costs against emissions code into core
* Renamed cost-by-scenario.html scenarios-ranked-by-cost.html
* Heavily refactored go.rb
* The list of cases tsv can now have empty lines and comments

#2015-04-23

* Merged in the flying brick code
* Can now specify the period to compare in the flying brick code
* Started to give go.rb some command line options
* Consolidated the different versions of gdx.rb into one file

#2015-04-21

* Merge in the investment rate output code

# 2015-04-20

* Merge in the scatter plot output code
* go.rb now produces output code

# 2015-04-17

* Added go.rb that will work through the whole process, including running multi-threaded

# 2015-04-16

* Refactored create-run-files.rb, including placing the run file template in a separate file
* create-run-files.rb now warns if it can't find a scenario dd file

# 2015-04-15

* Refactored create-list-of-cases.rb
* create-list-of-cases.rb now warns if scenario files don't exist

# 2015-04-06

* Fixed errors in generated emissions constraint files
