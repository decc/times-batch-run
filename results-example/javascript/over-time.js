var category_file_name = "electricity_to_low_or_high_carbon.tsv";
var data_file_name = "electricity-flows.json";
var details_file_name = "detailed-electricity.html";
var y_max = 1000;
var y_min = 0;
var y_label = "TWh/yr";
var category_for_name;
var code_lookup = code_to_name_lookup();
var data;
var formatted_data;
var aggregated_data;
var case_name;
var year_for_data = [2010, 2015, 2020, 2025, 2030, 2035, 2040, 2045, 2050];

var case_loaded = false;
var code_lookup_loaded = false;
var category_for_name_loaded = false;

function go() {
  category_for_name = name_to_category_lookup();
  settings = window.location.hash.slice(1).split(',');
  case_name = settings[0];
  load_case(case_name);
};

function load_case(case_name) {
  d3.json(url_for_case_data(case_name), process_case);
}

function process_case(individual_case) {
  data = d3.map(individual_case.processes_by_year);
  case_loaded = true;
  proceed();
}

function proceed() {
  if(all_loaded()) {
    reformat_data();
    aggregate_data();
    draw();
    draw_links();
  };
}

function all_loaded() {
  return case_loaded && code_lookup_loaded && category_for_name_loaded;
}

function reformat_data() {
  formatted_data = d3.map();
  data.forEach(function(series_name, series_data) {
    series = {};
    series.key = series_name;
    series.value = [];
    total = 0;
    values = d3.map(series_data);
    year_for_data.forEach(function(year_for_data) {
      value = values.get(year_for_data) || 0;
      total += value;
      series.value.push({x:year_for_data, y: value});
    });
    series.total = total;
    formatted_data.set(series_name, series);
  });
}

function aggregate_data() {
  aggregated_data = d3.map();
  formatted_data.forEach(function(series_name, series) {
    var category = category_for_name(series_name);
    aggregate_into(category, series);
  });
};

function aggregate_into(series_name, series) {
  var other = existing_data_for(series_name);
  var i;
  other.total = other.total + series.total;
  for(i=0; i<series.value.length; i++) {
    other.value[i].y = other.value[i].y + series.value[i].y;
  }
}

function existing_data_for(series_name) {
  if(aggregated_data.has(series_name)) {
    return aggregated_data.get(series_name);
  } else {
    var new_series = {
      key: series_name,
      value: year_for_data.map(function(year) { return { x: year, y: 0 }; }),
      total: 0
    };
    aggregated_data.set(series_name, new_series);
    return new_series;
  }
}

function name_to_category_lookup() {
  var regexps = [];

  d3.tsv(category_file_name).get(function(error, rows) {
    rows.forEach(function(row) {
      regexps.push([new RegExp("^"+row['Process']), row['Sector']]);
    });
    category_for_name_loaded = true;
    proceed();
  });

  function lookup(code) {
    for(var i=0; i<regexps.length; i++) {
      var regexp = regexps[i][0];
      if(regexp.test(code)) {
        var sector = regexps[i][1];
        return sector;
      }
    }
    return code;
  };

  return lookup;
}


function draw() {
  var chart = timeSeriesStackedAreaChart()
    .max_value(y_max)
    .min_value(y_min)
    .unit(y_label);

  d3.select('#chart')
    .datum(aggregated_data)
    .call(chart);

}

function draw_links() {
  var link_years = [2010,2020,2030,2040];
  var links = d3.select('#links').selectAll("li").data(link_years);

  var new_links = links.enter().append("li").append("a");

  links.exit().remove();

  links.select("a")
    .text(function(d) { return "What changes over the "+d+"s" })
    .attr("href", function(d) { return details_file_name+"#"+case_name+","+case_name+","+d+","+(d+10); });

}

function code_to_name_lookup() {
  var codes = d3.map();

  d3.tsv("codes.tsv").get(function(error, rows) {
    rows.forEach(function(row) {
      codes.set(row['Code'], row['Short']);
    });
    code_lookup_loaded = true;
    proceed();
  });

  function lookup(code) {
    return codes.get(code) || code;
  };

  return lookup;
}


function url_for_case_data(case_name) {
  return case_name + "/"+data_file_name;
};
