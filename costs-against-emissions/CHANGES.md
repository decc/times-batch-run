# 2015-04-23

* Can now specify which scenarios form the basis of the comparison

# 2015-04-20

* Refactored so that draws data about individual cases stored in individual files in individual folders
* Refactored update-data.rb to allow any number of tsv files to be referenced
* Renamed index.html to cost-emissions-scatter.html
* Refactored update-data.rb into a class with the potential to set a target directoy
* update-data.rb now copies the output html and javascript into the target directory

# 2015-04-17

* Now replaces NIL scenarios with Default_ScenarioName rather than removing them

# 2015-04-08

* On flying brick, tweaked some of the look and feel

# 2015-04-07

* Added first attempt at a flying brick to compare scenarios
* Fixed so that data extraction copes with GDX files from cases that failed to optimize
* Updated example data
* Fixed so that works with scenario names that start with a number
* Added a y-zoom button to main scatter plot

# 2015-04-04

* Added a cost-by-scenario.html view, mostly for diagnostic purposes
* In scatter view, only show scenarios that vary by case
* In scatter view, can now hover over scenario filter table

# 2015-04-03

* Now optionally has a scenarios attribute on the data, which can be used to filter results
* Axes now autoscale
* Renamed scenarios to cases to match VEDA language
* Chart now adjusts to match browser window size

# 2015-04-02

* First release
