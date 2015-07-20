var prices_that_we_care_about = ["GHG-NO-IAS-YES-LULUCF-NET", "GHG-YES-IAS-YES-LULUCF-NET", "GHGTOT", "CO2TOT"];
var years = [2010, 2015, 2020, 2025, 2030, 2035, 2040, 2045, 2050];
var price_format = d3.format(",.0f");
var case_name = undefined;
var data = [];
var cases = d3.map();

var case_names = window.location.hash.slice(1).split(',');
case_names.forEach(load_case);

function load_case(case_name) {
  d3.json(''+case_name+"/carbon-prices.json", case_loaded);
}

function case_loaded(case_data) {
  cases.set(case_data.name, case_data);
  if(all_cases_loaded()) { draw(); }
}

function all_cases_loaded() {
  return cases.size() == case_names.length;
}

function draw() {
  reformatCases();
  displayCaseName();
  drawChart();
  drawTable();
}

function reformatCases() {
  data = cases.values().map(reformat);
}

function reformat(case_data) {
  var new_values = [];
  years.forEach(function(year) {
    var possible_prices = prices_that_we_care_about.map(function(commodity) {
      if(case_data.prices[commodity]) {
        return case_data.prices[commodity][year] || 0;
      } else {
        return 0;
      }
    });
    new_values.push({year: year, value: d3.max(possible_prices)});
  });
  return { name: case_data.name, prices: new_values };
}

function displayCaseName() {
  d3.selectAll(".case_name").text(case_name);
}

function drawChart() {
  var chart_width = 500;
  var chart_height = Math.ceil(chart_width * 0.5);
  var chart = linechart(chart_width, chart_height);

  d3.select("#chart")
    .datum(data)
    .call(chart);
};

function linechart(width, height) {

  var margin = {top: 30, right: 75, bottom: 30, left: 50};

  var unit = "£/tCO2e";

  var x = d3.scale.linear()
    .domain([2010, 2050])
    .range([0, width - margin.left - margin.right]);

  var y = d3.scale.linear()
    .domain([0,5000])
    .range([height - margin.top - margin.bottom, 0]);

  var xAxis = d3.svg.axis()
    .tickFormat(d3.format("0f"))
    .scale(x)
    .orient("bottom");

  var yAxis = d3.svg.axis()
    .scale(y)
    .orient("left");

  var scenario_colors = d3.scale.category10();

  var line = d3.svg.line()
    .x(function(d) { return x(d.year); })
    .y(function(d) { return y(d.value); });

  // Don't let scenario labels get any closer than this (in pixels)
  var minimum_space_between_labels = 18;

  // This makes sure that labels don't overlap by
  // checking that they are at least minimum_space_between_labels
  // apart and, if not, shuffling them up and down.
  function ensure_labels_are_far_enough_apart(labels) {
    var i, label_position_changed, lower_label, label, y_difference;
    // CHECK: Does resorting ruin the data binding in d3?
    labels.sort(function(a,b) { return a.label_y - b.label_y; }); // Need to be in ascending order
    do {
      label_position_changed = false;
      labels.each(function(label, i) {
        if(i == 0) {
          lower_label = label;
        } else {
          y_difference = label.label_y - lower_label.label_y;
          // If labels are overlaping, nudge them apart by 2 pixels then loop again
          if(y_difference >= 0 && y_difference < minimum_space_between_labels) {
            lower_label.label_y = lower_label.label_y - 1;
            label.label_y = label.label_y + 1;
            label_position_changed = true;
          }
          lower_label = label;
        }
      });
    } while(label_position_changed);

  }

  function chart(selection) {
    selection.each(function(data) {
      if(data == undefined) { return; }

      var svg = d3.select(this).selectAll("svg").data([data]);

      // Create any new chart areas
      var new_svg = svg.enter().append("svg").append("g").attr("class", "canvas");
      new_svg.append("g").attr("class", "commodities");
      new_svg.append("g").attr("class", "x axis");
      new_svg.append("g").attr("class", "y axis");
      new_svg.append("text")
      .attr('text-anchor', "end")
      .attr('y', -7)
      .attr("class", "y_axis_label");

    // Update the outer dimensions.
    svg.attr("width", width)
      .attr("height", height);

    // Update the x-axis 
    svg.select(".x.axis")
      .attr("transform", "translate(0," + y.range()[0] + ")")
      .call(xAxis);

    svg.select(".y.axis")
      .call(yAxis);

    svg.select(".y_axis_label").text(unit);

    // Update the inner dimensions.
    var g = svg.select("g.canvas")
      .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

    // Update the scenarios
    var commodities = g.select(".commodities").selectAll("g.commodity")
      .data(Object, function(d) { return d.name; });

    commodities.enter()
      .append("g")
      .attr("class", function(d) { return "commodity "+d.name })
      .append("path")
      .attr("class", function(d) { return "commodity "+d.name })
      .attr("stroke", function(d) { return scenario_colors(d.name); });

    commodities.exit().remove()

      commodities.select("path")
      .attr("d", function(d) { return line(d.prices); });

    // Update the line markers
    var markers = commodities.selectAll("circle")
      .data(function(d) { return d.prices; });

    markers.enter().append("circle")
      .attr("r", 2)
      .attr("fill", function(d) { return scenario_colors(d.name); }); // FIXME: This picks up the wrong colour!

    markers.exit().remove();

    markers
      .attr("cx", function(d) { return x(d.year); })
      .attr("cy", function(d) { return y(d.value); });

    // Update the scenario labels
    labels = g.select(".commodities").selectAll("text.commodity")
      .data(function(commodities) { 
        commodities.forEach(function(d) {
          if(d.prices.length > 0) {
            d.label_y = y(d.prices[d.prices.length-1].value) // The y-position of the final data point in the scenario data (assumes this is the final year)
          }
        });
        return commodities;
      }, 
      function(d) { return d.name } // Make sure we always match by name
      );

    labels.enter().append("text")
      .text(function(d) { return d.name })
      .attr("dy", 2)
      .attr("dx", 1)
      .attr("class", function(d) { return "scenario "+d.name })
      .attr("fill", function(d) { return scenario_colors(d.name); })
      .on("mouseover", function(d) { // This does the fancy higlighting as the mouse moves over the labels
        commodities
        .classed("highlight", false)
        .classed("no_highlight", true);

      labels
        .classed("highlight", false)
        .classed("no_highlight", true);

      g.selectAll("."+d.name)
        .classed("highlight", true)
        .classed("no_highlight", false); 

      }).on("mouseout", function(d) {
        labels
        .classed("highlight", false)
        .classed("no_highlight", false);

      commodities
        .classed("highlight", false)
        .classed("no_highlight", false); 
      }).on("click", function(d) {  
        window.location = "case.html#"+d.name;
      });


    labels.call(ensure_labels_are_far_enough_apart);

    labels
      .attr("x", x.range()[1])
      .attr("y", function(d) { return d.label_y; });

    labels.exit().remove();
    });
  };

  chart.autoscale = function(_) {
    if (!arguments.length) return autoscale;
    autoscale = _;
    return chart;
  }
  
  chart.unit = function(_) {
    if (!arguments.length) return unit;
    unit = _;
    return chart;
  }


  return chart; 
}

function drawTable() {
  var table = annualDataTable()
              .columns(function(d) { return d.prices })
              .cell(function(d) { return price_format(d.value); });

  d3.select("tbody#prices")
    .datum(data)
    .call(table);
};


function annualDataTable() {

  var columns = function(d) { return d.values; }
  var cell = function(d) { return d.value; }
  var name = function(d) { return d.name; }
  var href = function(d) { return "case.html#"+d.name; }

  function table(selection) {

    var rows = selection.selectAll("tr").data(Object);

    rows.enter().append("tr");

    rows.exit().remove();

    rows.attr("class", function(d) { return d.name; });

    var name_cells = rows.selectAll("td.name").data(function(d) { return [d]; }); 

    name_cells.enter().append("td").attr("class", "name").append("a");

    name_cells.exit().remove();

    name_cells.select("a")
      .attr("href", href)
      .text(name);

    var value_cells = rows.selectAll("td.value").data(columns);

    value_cells.enter().append("td").attr("class", "value");

    value_cells.exit().remove();

    value_cells.text(cell);
  }

  table.name = function(_) {
    if (!arguments.length) return name;
    name = _;
    return table;
  };

  table.columns = function(_) {
    if (!arguments.length) return columns;
    columns = _;
    return table;
  };

  table.cell = function(_) {
    if (!arguments.length) return cell;
    cell = _;
    return table;
  };

  return table;
}

