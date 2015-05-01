# Batch running for UK TIMES

You can use VEDA Front End to batch run a number of cases in TIMES. These scripts go further, by generating a large number of cases by assembling together scenarios, and then executing them.

They are &copy; 2015 Tom Counsell and released under an MIT license.

They are available from: https://github.com/decc/times-batch-run please report any bugs there.

## INSTALATION

Requires:

* UK TIMES
* Ruby 2.2

## RUNNING

The rough steps are:

### Part 1, get all the scenario files out of VEDA:

1. Open VEDA_FE
2. Select Basic Functions > Case Manager
3. In the scenarios list, select all the possible scenarios you might want to use (you could just click All at the bottom)
4. Check the box 'Create DD only'
5. Click Solve and wait

### Part 2, generate all the case files and results

1. Edit possible_scenarios.tsv in Excel and save as a tsv file, the instructions in that tsv file should help
2. Run `ruby go.rb`

### Options

Take a look at the source for each file to see further options.

The most important options relate to correctly setting the VEDA_FE directory for your system

