# UK TIMES Build rates and investment costs

This script takes the results of one or more runs of the UK TIMES energy model and
plots the build rates, cost per unit and total investment costs for each process
in the model.

See http://decc.github.io/times-build-rates/ for example output

## Usage

Not ready for use yet:

``ruby update-data.rb <gdx-file> <optional-second-gx-file>``

If you don't specify a gdx file, then it uses a couple of test examples.

gdx files are usually found in the VEDA_FE/GAMS_WrkTIMES/GamsSave directory with the same name as the TIMES case.


## Hacking

Authoritative source at:

https://github.com/decc/times-build-rates

## Updating UnitsForEachProcess.csv

If you add a new process, then you need to add the unit in UnitsForEachProcess.csv

This file is manually created. You need to:
1. Select the 'Process view' on VEDA FE
2. Select all processes
3. Highlight the Process, ActUnit and	CapUnit columns (easiest to click in a cell then use the shift key and the arrow keys).
4. Copy (ctrl-c)
5. Open Excel
6. Paste
7. Save as 'csv'


