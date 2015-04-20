# COST VERSUS EMISSIONS FOR UK TIMES

These scripts generate a scatterplot of system costs against emissions
with data extracted from the output of the TIMES energy system model.

https://github.com/decc/times-cost-versus-emissions

&copy; 2015 Tom Counsell - Licensed under an [MIT](http://opensource.org/licenses/MIT) open source license.

## Instalation

Requirements:

1. A copy of TIMES
2. Ruby 2.2

## Usage

Run the TIMES model, ideally many times.

Find out where the resulting GDX files are saved (usually VEDA_FE/GAMS_WrkTIMES/GamsSave)

Run:

    ruby update-data.rb <location_of_gdx_file_or_files>

Where location_of_gdx_file_or_files points to one or more GDX files. You can get all of them in a folder by using *.gdx like this:

    ruby update-data.rb GAMS_WrkTIMES/GamsSave/*.gdx

Then open index.html in your web browser.

Some web browsers (e.g., Google Chrome) don't allow web pages opened from the file system to access data. In these cases, you need to start a server.

This command will start a simple server:

    ruby -run -e httpd .  -p 8000

The results can then be viewed at http://localhost:8000

To stop the server, press ctrl-C.

## More advanced usage

If you have a list of cases, as generated in times-batch-run/create-list-of-cases.rb, then you can point to that as the first argument. This information can then be used to colour and filter the scatterplot.

e.g.:

  ruby update-data.rb times-batch-run/cases.tsv GAMS_WrkTIMES/GamsSave/*.gdx

## License

The MIT License (MIT)

Copyright (c) 2015 Tom Counsell

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
