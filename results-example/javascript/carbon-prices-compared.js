var prices_that_we_care_about = ["GHG-NO-IAS-YES-LULUCF-NET", "GHG-YES-IAS-YES-LULUCF-NET", "GHGTOT", "CO2TOT"];
var y_axis_label = "£/tCO2e";
var years = [2010, 2015, 2020, 2025, 2030, 2035, 2040, 2045, 2050];
var price_format = d3.format(",.0f");
var case_names;
var data = [];
var cases = d3.map();
var max_y = 0;
var min_y = 0;

window.addEventListener("hashchange",function() { window.location.reload() });

function go() {
  case_names = window.location.hash.slice(1).split(',');
  case_names.forEach(load_case);
}

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
    var biggest_value = d3.max(possible_prices);
    max_y = max_y < biggest_value ? biggest_value : max_y;
    min_y = min_y > biggest_value ? biggest_value : min_y;
    new_values.push({year: year, value: biggest_value});
  });
  return { name: case_data.name, prices: new_values };
}

function drawChart() {
  var chart_width = window.innerWidth;
  var chart_height = window.innerHeight - d3.select("#chart").node().offsetTop;
  var chart = linechart()
                .y_axis_label(y_axis_label)
                .y_range([min_y, max_y])
                .width(chart_width)
                .height(chart_height);

  d3.select("#chart")
    .datum(data)
    .call(chart)
    .call(chart.markers)
    .call(chart.labels);
};

function drawTable() {
  var table = annualDataTable()
              .columns(function(d) { return d.prices })
              .cell(function(d) { return price_format(d.value); });

  d3.select("tbody#prices")
    .datum(data)
    .call(table);
};

function linechart() {

  var margin = {top: 30, right: 200, bottom: 30, left: 60};
  var width = 500;
  var height = 250;
  var markerRadius = 4;

  var y_axis_label_position = -(margin.top/2);
  var y_axis_label = "£/tCO2e";

  var x_range = [2010, 2050];
  var y_range = [0, 5000];

  var x = function(d) { return d.year };
  var y = function(d) { return d.value };

  var xScale = d3.scale.linear();
  var yScale = d3.scale.linear();

  var scaled_x = function(d) { return xScale(x(d)); };
  var scaled_y = function(d) { return yScale(y(d)); };

  var xAxis = d3.svg.axis()
    .tickFormat(d3.format("0f"))
    .scale(xScale)
    .orient("bottom");

  var yAxis = d3.svg.axis()
    .scale(yScale)
    .orient("left");

  var series_colours = d3.scale.category10();

  var line = d3.svg.line()
    .x(scaled_x)
    .y(scaled_y);

  var series_name = function(d) { return d.name; }
  var series_css = function(d) { return d.name; }
  var points = function(d) { return d.prices; }

  var minimum_space_between_labels = 20; // Pixels

  function chart(selection) {
      // Create a new SVG if required
      var svg = selection.selectAll("svg").data(function(d) { return [d]; });

      // Create any new chart areas
      var new_svg = svg.enter().append("svg").append("g").attr("class", "canvas");

      new_svg.append("g").attr("class", "data");
      new_svg.append("g").attr("class", "x axis");
      new_svg.append("g").attr("class", "y axis");

      // y-axis label
      new_svg.append("text")
        .attr('text-anchor', "end")
        .attr('y', y_axis_label_position) 
        .attr("class", "y_axis_label");

      // Update the outer dimensions.
      svg.attr("width", width)
        .attr("height", height);

      // Update the y-axis
      yScale.domain(y_range)
        .range([height - margin.top - margin.bottom, 0])
        .nice();

      svg.select(".y.axis")
        .call(yAxis);

      svg.select(".y_axis_label").text(y_axis_label);

      // Update the x-axis 
      xScale.domain(x_range)
        .range([0, width - margin.left - margin.right]);

      svg.select(".x.axis")
        .attr("transform", "translate(0," + yScale.range()[0] + ")")
        .call(xAxis);

      // Update the inner dimensions.
      var g = svg.select("g.canvas")
        .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

      // Update the series
      var series = g.select(".data").selectAll("g.series")
        .data(Object, series_name);

      series.exit().remove()

      var new_series = series.enter()
        .append("g")
          .attr("class", function(d) { return "series "+series_css(d) })
          .on("mouseover",hover_start)
          .on("mouseout", hover_end) 
          .on("click", click);

      new_series
        .append("path");

      // Update the series line
      series.select("path")
        .attr("d", function(d) { return line(points(d)); });

  };

  chart.markers = function(selection) {
    var markers = selection.selectAll(".series").selectAll("circle")
      .data(points);

    markers.enter().append("circle")
      .attr("r", markerRadius);

    markers.exit().remove();

    markers
      .attr("cx", scaled_x)
      .attr("cy", scaled_y);
  }

  chart.labels = function(selection) {
    position_labels(selection.data()[0]);

    var label = selection.selectAll("g.series").selectAll("text")
      .data(function(d) { return [d]; }, series_name);

    label.exit().remove();

    label.enter().append("text")
      .text(series_name)
      .attr("dy", 2)
      .attr("dx", 5);

    label
      .attr("x", xScale.range()[1])
      .attr("y", function(d) { return d.label_y; });
  }

  function hover_start(d) {
    d3.selectAll(".series")
      .classed("highlight", false)
      .classed("no_highlight", true);

    d3.selectAll("."+d.name)
      .classed("highlight", true)
      .classed("no_highlight", false); 
  }

  function hover_end(d) {
    d3.selectAll(".highlight").classed("highlight", false)
    d3.selectAll(".no_highlight").classed("no_highlight", false)
  }

  function click(d) {
    window.location = "case.html#"+series_name(d);
  }
  
  // This makes sure that labels don't overlap by
  // checking that they are at least minimum_space_between_labels
  // apart and, if not, shuffling them up and down.
  function position_labels(labels) {
    labels.forEach(add_initial_label_position);
    labels.sort(function(a,b) { return a.label_y - b.label_y; }); // Need to be in ascending order
    var i = 0;
    var length = labels.length;
    var label_position_changed = false;
    var step = 1;
    var y_difference = 0;
    var gap_below = 0;
    var gap_above = 0;
    var iterations = 100;
    var a_name, a_label_y;

    do {
      label_position_changed = false;

      // Shuffle cells down
      for(i = 0; i < length; i++) {
        a_name = labels[i].name;
        a_label_y = labels[i].label_y;
        if(i == 0) {
          gap_below = 1e6;
        } else {
          gap_below = labels[i].label_y - labels[i-1].label_y;
        }

        if(i == (length-1)) {
          gap_above = 1e6;
        } else {
          gap_above = labels[i+1].label_y - labels[i].label_y;
        }

        if(gap_below == 0 && gap_above == 0) { 
          // Do nothing, stuck
        } else if( gap_above > minimum_space_between_labels && gap_below > minimum_space_between_labels) {
          // Do nothing, all ok.
        } else if(gap_below == 0) {
          labels[i].label_y = labels[i].label_y + Math.min(gap_above, minimum_space_between_labels - gap_below);
          label_position_changed = true;
        } else if(gap_above == 0) {
            labels[i].label_y = labels[i].label_y - Math.min(gap_below, minimum_space_between_labels-gap_above);
            label_position_changed = true;
        } else if(gap_above >= gap_below) {
          if(gap_below < minimum_space_between_labels) {
            labels[i].label_y = labels[i].label_y + Math.min(gap_above, minimum_space_between_labels - gap_below);
            label_position_changed = true;
          }
        } else if(gap_below > gap_above) {
          if(gap_above < minimum_space_between_labels) {
            labels[i].label_y = labels[i].label_y - Math.min(gap_below, minimum_space_between_labels - gap_above);
            label_position_changed = true;
          }
        }

        if(labels[i].label_y < 0) { labels[i].label_y = 0; }
      }
      //label_position_changed = false;

      iterations--;
    } while(iterations > 0 && label_position_changed);
  }


  function add_initial_label_position(d) {
    var series = points(d);
    var last_point = series[series.length-1];
    d.label_y = scaled_y(last_point);
  }

  chart.autoscale = function(_) {
    if (!arguments.length) return autoscale;
    autoscale = _;
    return chart;
  }

  chart.y_axis_label = function(_) {
    if (!arguments.length) return y_axis_label;
    y_axis_label = _;
    return chart;
  }
  chart.x_range = function(_) {
    if (!arguments.length) return x_range;
    x_range = _;
    return chart;
  }

  chart.y_range = function(_) {
    if (!arguments.length) return y_range;
    y_range = _;
    return chart;
  }

  chart.width = function(_) {
    if (!arguments.length) return width;
    width = _;
    return chart;
  }

  chart.height = function(_) {
    if (!arguments.length) return height;
    height = _;
    return chart;
  }


  return chart; 
}


function annualDataTable() {

  var columns = function(d) { return d.values; }
  var cell = function(d) { return d.value; }
  var name = function(d) { return d.name; }
  var href = function(d) { return "case.html#"+d.name; }

  function table(selection) {

    var rows = selection.selectAll("tr").data(Object);

    rows.enter().append("tr")
      .on("mouseover",hover_start)
      .on("mouseout", hover_end);

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
  
  function hover_start(d) {
    d3.selectAll(".series")
      .classed("highlight", false)
      .classed("no_highlight", true);

    d3.selectAll("."+d.name)
      .classed("highlight", true)
      .classed("no_highlight", false); 
  }

  function hover_end(d) {
    d3.selectAll(".highlight").classed("highlight", false)
    d3.selectAll(".no_highlight").classed("no_highlight", false)
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

