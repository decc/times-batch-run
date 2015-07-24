y_axis_label = undefined;

var code_lookup;
var code_to_name_lookup_loaded_flag = false;
var settings;
var flows_that_we_care_about;
var flows_that_we_have_matched = d3.set();
var regexp_for_flows_that_we_care_about;
var attribute_we_want_to_plot = 'INSTCAP'

function go() {
  settings = window.location.hash.slice(1).split(';');
  case_names = settings[0].split(",");
  flows_that_we_care_about = settings[1].split(",");
  code_lookup = code_to_name_lookup();
}

function start() {
  d3.select(".codes").text(flows_that_we_care_about.join(", "));
  regexp_for_flows_that_we_care_about = flows_that_we_care_about.map(function(s) { return RegExp(s); });
  case_names.forEach(load_case);
}

function load_case(case_name) {
  d3.json(''+case_name+"/build-rates.json", case_loaded);
}

function case_loaded(case_data) {
  cases.set(name_from_case_data(case_data), case_data);
  if(all_cases_loaded()) { draw(); }
}

function reformatCases() {
  data = cases.values().map(function(case_data) {
      return reformat(case_data);
  });
  drawListOfFlows();
}

function drawListOfFlows() {
  var list = d3.select("#list_of_flows").selectAll("li")
    .data(flows_that_we_have_matched.values());

  list.exit().remove();

  list.enter().append("li").append("a");

  list.select("a")
    .attr("href", function(d) { return "#"+case_names.join(",")+";"+d })
    .text(function(d) { return code_lookup(d)+" ("+d+")"; });

  list
    .sort(function(a,b) { return d3.ascending(code_lookup(a), code_lookup(b)) });
}

function name_from_case_data(case_data) {
  return case_data[0][attribute_we_want_to_plot][0]["name"];
}

function reformat(case_data) {
  var new_values = [];
  var relevant_processes = case_data.filter(function(d) { 
    var process_name = d['p'];
    for(var i=0; i<regexp_for_flows_that_we_care_about.length; i++) {
      if(regexp_for_flows_that_we_care_about[i].test(process_name)) { 
        flows_that_we_have_matched.add(process_name);
        return true; 
      }
    }
    return false;
  });

  if(y_axis_label == undefined && relevant_processes.length > 0) {
    y_axis_label = "" + relevant_processes[0][attribute_we_want_to_plot][0].unit + "/yr";
  };

  var relevant_attribute = relevant_processes.map(function(d) { 
    return d[attribute_we_want_to_plot][0].data 
  });

  years.forEach(function(year) {
    var total_for_year = 0;
    relevant_attribute.forEach(function(process) {
      var values_for_process_in_year = process.filter(function(d) { return d['allyear'] == year });
      values_for_process_in_year.forEach(function(d) {
        total_for_year = total_for_year + d['val'];
        });
      });

    max_y = max_y < total_for_year ? total_for_year : max_y;
    min_y = min_y > total_for_year ? total_for_year : min_y;
    new_values.push({year: year, value: total_for_year});
  });
  return { name: name_from_case_data(case_data), prices: new_values };
}

function code_to_name_lookup() {
  var codes = d3.map();

  d3.tsv("codes.tsv").get(function(error, rows) {
    rows.forEach(function(row) {
      codes.set(row['Code'], row['Short']);
    });
    code_to_name_lookup_loaded_flag = true;
    start();
  });

  function lookup(code) {
    var official_form = code.replace(/^(P|C)-/i, '');
    return codes.get(official_form) || official_form;
  };

  return lookup;
}
