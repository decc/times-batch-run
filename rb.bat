rem *****Batch file to run UKTM scenarios*****
rem by Fernley Symons 5:24 PM 03-Nov-16
rem If you edit this file you need not go near the command line itself.
rem The following is taken from the BAT which is invoked if you click on 
rem "Start command prompt with ruby". It basically pre-pends the ruby path to the
rem path environment variable. I'm not sure why this is necessary (but see REM note)...
rem this (current) BAT can be in any place on your computer. E.g. it doesn't have to be in WrkTIMES
rem *
REM Determine where is RUBY_BIN (location where Ruby is installed - NB you may need to edit "Ruby22-x64" to reflect pathway for your Ruby version)
SET RUBY_BIN="C:\Ruby22-x64\bin"
POPD
REM Add RUBY_BIN to the PATH
REM RUBY_BIN takes higher priority to avoid other tools
REM conflict with our own (mainly the DevKit)
SET PATH=%RUBY_BIN%;%PATH%
SET RUBY_BIN=
cd C:\VEDA\Veda_FE\GAMS_WrkTIMES
rem The following line actually runs the UKTM ruby code. Either a) always use the same tsv file name (and change it after a run to reflect
rem the run!), or edit it to point to different tsvs. There's nothing to stop you adding more lines to "batch run" tsv batch runs...
ruby "C:\Users\DECC\Documents\GitHub\times-batch-run\go.rb" "C:\VEDA\Veda_FE\GAMS_WrkTIMES\v1.2.3_d0.2.2_DNP;ERP03.tsv"
pause

