#2015-07-08

* Updated the cost-emissions scatter chart
* Refactored the over-time charts

#2015-07-07

* GDX now caches results
* Now does results production on a seperate thread from calculation
* When you request --results-only it now produces results in separate processes

#2015-07-06

* Now generates data about electricity generation (excluding CHP at the moment)
* go.rb can now multi-thread when operating in results only mode
* First attempt at data about road transport and heating
* New version of cost-emissions scatter chart

#2015-07-05

* Removed the dd file check from the monte-carlo generation (it still happens in case file generation)
* monte-carlo no longer sorts the list of cases it generates
* Added sensitivities.rb that generates all the sensitivites in possible_scenarios.tsv (treating the first column as the base)
* Added monte-carlo-sensitivities.rb that repeatedly generates all the senstivities against a random baseline
* go.rb now defaults to using monte-carlo-sensitivities and to generating 2000 cases

#2015-06-30

* Fixed typo in total_cap.dd (GAMS uses = for equality test, not ==)
* Added an after_2050_same_as_2050 dd file to allow 2055 and 2060 emissions to be automatically aligned with those in 2050

#2015-06-30

* Can now click on a case to see details about that individual case
* Added missing demand scenarios to possible_scenarios.tsv

#2015-06-29

* Settting a total_cap constraint to 999 will now REMOVE the constraint, and any ETS constraint.

#2015-06-28

* Moved flying bricks labels higher

#2015-06-26

* Refactored the flying-bricks to share code

#2015-06-25

* Added a update-index.rb utility to the results folder to allow easy index updates
* Added a default index.html page to the results folder

#2015-06-24

* Added a new cost difference output
* Fixed a bug in the counting of traded emissions in the detailed and sectoral emissions charts
* Added a sectoral-costs output
* Altered sectoral-emissions to match sectoral-costs approach
* Fixed axis labelling on flying brick charts

#2015-06-23

* Altered the incremental cost by scenario to show compared scenarios in hash

#2015-06-22

* Refactoring: extracted list of cases into its own class
* Added a detailed emissions flying brick dump and chart
* Replaced the update- commands with a single update-results-example.rb
* Updated possible_scenarios.tsv to match uktm_model_v1.2.0_carbonaccounting_v0.0.2
* Now productes a sectoral emissions flying brick

#2015-06-18

* Refactoring for readability

#2015-06-15

* Tinker with ets_cap.dd to try and ensure trading happens
* Fix the tie line to use new carbon budget scenario name
* Updated the scatter to show the scenarios in two columns

#2015-06-11

* Remove obsolete dd-file-generators
* Cost-emissions scatter now shows the Carbon Budget rather than actual emissions

#2015-06-08

* Start the wiring for the new carbon budget accounting approach in batch running

#2015-06-03

* Fixed a bug in uc_elc in default possible_scenarios.tsv

#2015-06-02

* The detailed cost page now updates when you manually change the hash
* The cost-emissions scatter now uses human readable scenario names, and calls them what-ifs

#2015-06-01

* The incremental costs by scenario now has a better opacity and changed ordering

#2015-05-19

* The detailed cost chart now shows percentage changes

#2015-05-14

* The detailed cost chart now uses human readable names, rather than codes
* The build rates chart now uses human readable names, rather than codes

#2015-05-11

* Fixed the go.rb command to respect the TIMES source folder setting

#2015-05-08

* Changed the label on the build rate chart to be clearer
* Added DDM build rate constraints to example possible_scenarios.tsv
* Added a command line switch --results-folder to go.rb to specify where results should go

#2015-05-07

* Fixed the chart with for the cost emissions scatter in IE9
* replace all "." in scenario names with "_" in CreateRunFiles

#2015-05-05

* The build rate chart by default only shows the top 10 costs
* The build rate chart adjusts its width to fit window
* go.rb now updates the results each time it solves a case
* Fixed the detailed costs view to create the correct hash tag on startup
* Renamed create-run-files.rb to create_run_files.rb for consistency
* Can now pass arguments to dd files

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
