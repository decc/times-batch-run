var code_to_name_lookup_loaded_flag = false;
var left_case_loaded_flag = false;
var right_case_loaded_flag = false;
var code_to_sector_lookup_loaded_flag = false;

function code_to_name_lookup() {
  var codes = d3.map();

  d3.tsv("codes.tsv").get(function(error, rows) {
    rows.forEach(function(row) {
      codes.set(row['Code'], row['Short']);
    });
    code_to_name_lookup_loaded_flag = true;
    proceed();
  });

  function lookup(code) {
    return codes.get(code) || code;
  };

  return lookup;
}

var code_lookup = code_to_name_lookup();

function code_to_sector_lookup() {
  var regexps = [];

  d3.tsv("process_to_sector.tsv").get(function(error, rows) {
    rows.forEach(function(row) {
      regexps.push([new RegExp("^"+row['Process']), row['Sector']]);
    });
    code_to_sector_lookup_loaded_flag = true;
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

var sector_lookup = code_to_sector_lookup();

var topic = "costs";
var left_case_name = undefined;
var right_case_name = undefined;

var a_name = "Scenario A";

var b_name = "Scenario B";

var data = {
  a_negative: [],
  a_positive: [],
  diff_positive: [],
  diff_negative: [],
  b_positive: [],
  b_negative: []
} 

var a_positive_total = 0, 
    b_positive_total = 0, 
    a_negative_total = 0, 
    b_negative_total = 0,
    diff_positive_total = 0,
    diff_negative_total = 0,
    b_total_over_a_total = 0,
    diff_over_a_total = 0;

var number_of_columns = 0;

var margin = {top: 40, right: 120, bottom: 30, left: 50},
    width = window.innerWidth - margin.left - margin.right,
    height = window.innerHeight - margin.top - margin.bottom;

var x = d3.scale.ordinal()
          .rangeRoundBands([130, width-130], .1);

var y = d3.scale.linear()
          .rangeRound([height, 0]);

var color = d3.scale.category20c();
var used_ids = d3.set(); // We use these to map from block name to colour

var minimum_pixels_for_display_stack = 15;
var minimum_value_for_display_stack = 0; // Set once scale is set
var minimum_pixels_for_display_brick = 2;
var minimum_value_for_display_brick = 0; // Set once scale is set
var minimum_pixels_for_label_y_spacing = 10;
var percent_format = d3.format(".0%");

var yAxis = d3.svg.axis()
              .scale(y)
              .orient("left")
              .tickFormat(d3.format(".0f"));

  var svg = d3.select("#chart").append("svg")
              .attr("width", width + margin.left + margin.right)
              .attr("height", height + margin.top + margin.bottom)
              .append("g")
              .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

  var backing = svg.append("g")
  .attr("id", "backing");

  backing.append("rect").attr("id", "backingleft");
  backing.append("rect").attr("id", "backingright");
  backing.append("rect").attr("id", "backingdiff");

  svg.append("g")
  .attr("class", "x axis")
  .append('line');

  svg.append("g")
  .attr("class", "y axis")
  .call(yAxis);

  svg.append("text")
  .attr("class", "axis")
  .attr("id","axislabel")
  .attr("text-anchor", "left")
  .attr("y", -15)
  .attr("x", -margin.left);

  svg.append("text")
  .attr("class", "stacklabel")
  .attr("id","leftlabel")
  .attr("text-anchor", "middle")
  .attr("y", -15);

  svg.append("text")
  .attr("class", "stacklabel")
  .attr("id","rightlabel")
  .attr("text-anchor", "middle")
  .attr("y", -15);

  svg.append("text")
  .attr("class", "stacklabel")
  .attr("id","decreaselabel")
  .attr("text-anchor", "middle")
  .attr("y", 55);

  svg.append("text")
  .attr("class", "stacklabel")
  .attr("id","increaselabel")
  .attr("text-anchor", "middle")
  .attr("y", 55);

  svg.append("text")
  .attr("class", "stacklabel")
  .attr("id","difflabel")
  .attr("text-anchor", "middle")
  .attr("y", -15)
  .attr("x", width/2);

  var differencegroup = svg.append("g").attr("class","diffrencegroup");
  var boxgroup = svg.append("g").attr("class", "boxgroup");
  var linegroup = svg.append("g").attr("class", "linegroup");
  var labelgroup = svg.append("g").attr("class", "labelgroup");

  differencegroup.append("line").attr("id","a_total_line");
  differencegroup.append("line").attr("id","b_total_line");
  differencegroup.append("line").attr("id","diff_total_line");
  differencegroup.append("text").attr("id","b_over_a_label").attr("dy","3").attr("text-anchor","end");
  differencegroup.append("text").attr("id","diff_over_a_total_label").attr("dy","3").attr("text-anchor","end");

  function set_scales() { 
    var y_domain = [0,0];
    // First we work out the extreme ends in order to set the scale
    if(a_negative_total < b_negative_total) {
      y_domain[0] = a_negative_total;
    } else {
      y_domain[0] = b_negative_total;
    }

    if(a_positive_total > b_positive_total) {
      y_domain[1] = a_positive_total;
    } else {
      y_domain[1] = b_positive_total;
    }

    // Set the y_domain of the y to cover the full data range
    y.domain(y_domain).nice();

    minimum_value_for_display_stack = Math.abs(y.invert(minimum_pixels_for_display_stack) - y.invert(0));
    minimum_value_for_display_brick = Math.abs(y.invert(minimum_pixels_for_display_brick) - y.invert(0));

    // Now we replace a bunch of values with 'other'
    data.a_positive = replace_with_other(data.a_positive, minimum_value_for_display_stack, 'a');
    data.a_negative = replace_with_other(data.a_negative, minimum_value_for_display_stack, 'a');
    data.b_positive = replace_with_other(data.b_positive, minimum_value_for_display_stack, 'b');
    data.b_negative = replace_with_other(data.b_negative, minimum_value_for_display_stack, 'b');
    data.diff_positive = replace_with_other(data.diff_positive, minimum_value_for_display_brick, 'diff');
    data.diff_negative = replace_with_other(data.diff_negative, minimum_value_for_display_brick, 'diff');

    // From that we can work out the x axis domain
    // Starts with 2 for the negative and positive of the first bar
    // then space for all the up bricks and down bricks
    // then a 2 for the negative and positive parts of the last bar
    number_of_columns = 2 + 1 + data.diff_positive.length + 1 + data.diff_negative.length + 1 + 2;
    x.domain(d3.range(number_of_columns)); 
  };

// This function takes an array of data, and for any parameter in that
// data that is below the threshold, combines that data into an 
// other category. It returns a smaller array of data that contains
// the 'other' and the category
var replace_with_other = function(data, threshold, parameter) {
  var other = { label: 'other' },
      new_data = [],
      value_collected = 0,
      value_in_other = 0;

  data.forEach(function(d) {
    var v = d[parameter];
    if(Math.abs(v) > threshold) {
      new_data.push(d);
      value_collected = value_collected + v;
    } else {
      value_in_other = value_in_other + v;
    }
  });

  other[parameter] = value_in_other;

  new_data.push(other);

  // Rely on data only being all positive or all negative
  // Then sort so largest (absolute) values are at the start
  new_data.sort(function(a,b) { 
    return Math.abs(b[parameter]) - Math.abs(a[parameter]);
  });

  return new_data;
}

// We need to make each of the data points stack correctly
var position_data = function() {
  var label_y, minimum_label_y_spacing;

  stack('ln', data.a_negative, 'a', 0, 0, 0); // Down
  stack('lp', data.a_positive, 'a', a_negative_total, 1, 0); // Up
  stack('dn', data.diff_negative.reverse(), 'diff', a_negative_total + a_positive_total, 3, 1); // Down
  stack('dp', data.diff_positive, 'diff', a_negative_total + a_positive_total + diff_negative_total, 3 + data.diff_negative.length + 1, 1); // Up
  stack('rp', data.b_positive, 'b', b_negative_total, 3 + data.diff_positive.length + 1 + data.diff_negative.length + 1 , 0); // Down
  stack('rn', data.b_negative, 'b', 0, 3 + data.diff_positive.length + 1 + data.diff_negative.length + 1 + 1, 0); // Up

  // Now we deal with the labels
  minimum_label_y_spacing =  Math.abs(y.invert(minimum_pixels_for_label_y_spacing) - y.invert(0));
  label_y = a_positive_total;

  data.diff_negative.forEach(function(d) { 
    var desired_y = d.y0;
    var minimum_y = label_y - minimum_label_y_spacing;
    if(minimum_y < desired_y) {
      desired_y = minimum_y;
      label_y = label_y - minimum_label_y_spacing;
    } else {
      label_y = desired_y;
    }
    d.label_y = desired_y;
  });

  label_y = b_positive_total;

  data.diff_positive.slice(0).reverse().forEach( function(d) { 
    var desired_y = d.y0;
    var minimum_y = label_y - minimum_label_y_spacing;
    if(minimum_y < desired_y) {
      desired_y = minimum_y;
      label_y = label_y - minimum_label_y_spacing;
    } else {
      label_y = desired_y;
    }
    d.label_y = desired_y;
  });
}

var stack = function(type, data, parameter, y_start, x_start, x_inc) {
  var y0, y1, x, y;
  x = x_start;
  y = y_start;
  data.forEach(function(d) {
    h = d[parameter];
    d.x = x;
    d.type = type;
    d.css = d.label.replace(/\W+/g,'');
    d.unique_id = d.type + d.css;
    used_ids.add(d.css);
    x = x + x_inc;
    if(h >= 0) {
      d.y0 = y;
      d.y1 = y + h;
      y = y+ h;
    } else {
      d.y1 = y;
      d.y0 = y + h;
      d.h = -h;
      y = y+h;
    }
  });
  return data;
}

var draw = function() {
  var lines, bricks, all_data, labels, label_lines;

  all_data = data.a_negative.concat(data.a_positive, data.diff_positive, data.diff_negative, data.b_positive, data.b_negative);

  color.domain(used_ids.values());

  // All the bricks
  bricks = boxgroup.selectAll(".brick").data(all_data, function(d) { return d.unique_id; });

  bricks.enter().append("rect");

  bricks.exit().remove();

  bricks
    .attr("class", function(d) { return "brick "+d.css; })
    .attr("fill", function(d) { return color(d.css); })
    .attr("x", function(d) { return x(d.x); })
    .attr("y", function(d) { return y(d.y1); })
    .attr("width", x.rangeBand())
    .attr("height", function(d) { return y(d.y0)-y(d.y1); });

  // Update the axes
  d3.select(".y.axis").call(yAxis);

  d3.select(".x.axis line")
    .attr('x1', 0)
    .attr('x2', width)
    .attr('y1', y(0))
    .attr('y2', y(0));

  // Labels
  d3.select('#axislabel').text(y_axis_label_text);

  labels = labelgroup.selectAll(".label").data(all_data, function(d) { return d.unique_id; });

  labels.exit().remove();

  labels.enter().append("text")
    .attr("dy", '0.3em');

  labels
    .text(function(d) { return code_lookup(d.label); })
    .attr("fill", function(d) { return color(d.css); })
    .attr("class", function(d) { return "label "+d.type+" "+d.css; })
    .attr("x", function(d) { return x(d.x);  })
    .attr("y", function(d) { return y((d.y0+d.y1)/2);  });

  svg.selectAll(".label.ln, .label.lp, .label.dn")
    .attr("text-anchor", "end");

  svg.selectAll(".label.ln, .label.lp")
    .attr("dx", -1);

  svg.selectAll(".label.rn, .label.rp")
    .attr("dx", x.rangeBand()+1);

  svg.selectAll(".label.dn, .label.dp")
    .attr("y", function(d) { return y(d.label_y)+6; })
    .attr("dx", x.rangeBand()/2);

  // Lines from labels to bricks
  label_lines = linegroup.selectAll(".labelline").data(data.diff_negative.concat(data.diff_positive), function(d) { return d.unique_id; });

  label_lines.enter().append("line")
    .attr('stroke-dasharray', '2 1');

  label_lines.exit().remove();

  label_lines
    .attr("stroke", function(d) { return color(d.css); })
    .attr("class", function(d) { return "labelline "+d.type+" "+d.css; })
    .attr("x1", function(d) { return x(d.x) + (x.rangeBand()/2); })
    .attr("x2", function(d) { return x(d.x) + (x.rangeBand()/2); })
    .attr("y1", function(d) { return y(d.y0)+1; })
    .attr("y2", function(d) { return y(d.label_y); });

  // Extra connecting lines
  var lines = linegroup.selectAll("line.connector.dp").data(data.diff_positive, function(d) { return d.unique_id; });

  lines.enter().append("line").attr("class", "connector dp");

  lines.exit().remove();

  lines
    .attr('x1', function(d) { return x(d.x-1); })
    .attr('x2', function(d) { return x(d.x)+x.rangeBand(); })
    .attr('y1', function(d) { return y(d.y0); })
    .attr('y2', function(d) { return y(d.y0); });

  lines = linegroup.selectAll("line.connector.dn").data(data.diff_negative, function(d) { return d.unique_id; });

  lines.enter().append("line").attr("class", "connector dn");

  lines.exit().remove();

  lines
    .attr('x1', function(d) { return x(d.x); })
    .attr('x2', function(d) { return x(d.x+1)+x.rangeBand(); })
    .attr('y1', function(d) { return y(d.y0); })
    .attr('y2', function(d) { return y(d.y0); });

  lines = linegroup.selectAll("line.connector.lefttodiff").data([1]);

  lines.enter().append("line").attr("class", "connector lefttodiff");

  lines.exit().remove();

  lines
    .attr('x1', function(d) { return x(1); })
    .attr('x2', function(d) { return x(3)+x.rangeBand(); })
    .attr('y1', function(d) { return y(a_negative_total + a_positive_total); })
    .attr('y2', function(d) { return y(a_negative_total + a_positive_total); });

  lines = linegroup.selectAll("#righttodiff").data([1]);

  lines.enter().append("line").attr("class", "connector").attr("id", "righttodiff");

  lines.exit().remove();

  lines
    .attr('x1', function(d) { return x(number_of_columns-4); })
    .attr('x2', function(d) { return x(number_of_columns-2)+x.rangeBand(); })
    .attr('y1', function(d) { return y(b_negative_total + b_positive_total); })
    .attr('y2', function(d) { return y(b_negative_total + b_positive_total); });

  lines = linegroup.selectAll("line.connector.left").data([1]);

  lines.enter().append("line").attr("class", "connector left");

  lines.exit().remove();

  lines
    .attr('x1', function(d) { return x(0); })
    .attr('x2', function(d) { return x(1)+x.rangeBand(); })
    .attr('y1', function(d) { return y(a_negative_total); })
    .attr('y2', function(d) { return y(a_negative_total); });

  lines = linegroup.selectAll("line.connector.right").data([1]);

  lines.enter().append("line").attr("class", "connector right");

  lines.exit().remove();

  lines
    .attr('x1', function(d) { return x(number_of_columns-2); })
    .attr('x2', function(d) { return x(number_of_columns-1)+x.rangeBand(); })
    .attr('y1', function(d) { return y(b_negative_total); })
    .attr('y2', function(d) { return y(b_negative_total); });

  d3.select('#leftlabel')
    .text(capitalize(topic)+" of "+a_name)
    .attr("x", x(2)/2);

  d3.select('#rightlabel')
    .text(capitalize(topic)+" of "+b_name)
    .attr("x", (x(number_of_columns-2)+width)/2);

  d3.select('#decreaselabel')
    .attr("x", x( Math.ceil(2+(data.diff_negative.length/2))))
    .attr("y", y(a_negative_total + a_positive_total)-20)
    .text("Reduce these "+topic);

  d3.select('#increaselabel')
    .attr("x", x(Math.ceil(((number_of_columns-3)+(number_of_columns-3-data.diff_positive.length))/2)))
    .attr("y", y(b_negative_total + b_positive_total)-20)
    .text("Increase these "+topic);

  d3.select('#difflabel').text("Difference in "+topic+" between the scenarios");

  svg.select("#backingleft")
    .attr("x", 5)
    .attr("width", x(2)+5)
    .attr("y", 0)
    .attr("height", height);

  svg.select("#backingright")
    .attr("x", x(number_of_columns-2)-5)
    .attr("width", x(2)+5)
    .attr("y", 0)
    .attr("height", height);

  svg.select("#backingdiff")
    .attr("x", x(3)-5)
    .attr("width", x(number_of_columns-3)-x(3)+5)
    .attr("y", 0)
    .attr("height", y(a_negative_total + a_positive_total + diff_negative_total)+50);

  var right_end_point_for_total_line = x.rangeExtent()[1] + (margin.right+100); // TODO: Why extra 100?

  // Now the lines to help highlight the percentage increase
  d3.select("#a_total_line")
    .attr('x1', function(d) { return x(1); })
    .attr('x2', function(d) { return right_end_point_for_total_line; })
    .attr('y1', function(d) { return y(a_positive_total + a_negative_total); })
    .attr('y2', function(d) { return y(a_positive_total + a_negative_total); });

  d3.select("#b_total_line")
    .attr('x1', function(d) { return x(number_of_columns-1); })
    .attr('x2', function(d) { return right_end_point_for_total_line; })
    .attr('y1', function(d) { return y(b_positive_total + b_negative_total); })
    .attr('y2', function(d) { return y(b_positive_total + b_negative_total); });

  d3.select("#diff_total_line")
    .attr('x1', function(d) { return x(1); })
    .attr('x2', function(d) { return right_end_point_for_total_line; })
    .attr('y1', function(d) { return y(a_positive_total + a_negative_total+diff_negative_total); })
    .attr('y2', function(d) { return y(a_positive_total + a_negative_total+diff_negative_total); });

  d3.select("#diff_over_a_total_label")
    .attr('x', function(d) { return right_end_point_for_total_line })
    .attr('y', function(d) { return y( ((a_positive_total + a_negative_total + diff_negative_total) + (a_positive_total + a_negative_total))/2) })
    .text(percent_format(diff_over_a_total)+" of "+topic+" change");

  d3.select("#b_over_a_label")
    .attr('x', function(d) { return right_end_point_for_total_line })
    .attr('y', function(d) { return y( (a_positive_total + a_negative_total + b_positive_total + b_negative_total)/2) })
    .text(percent_format(b_total_over_a_total-1)+" of "+topic+" "+direction(b_total_over_a_total-1));
}

function direction(number) {
  return number > 0 ? "increase" : "decrease";
}

var add_data_point = function(d) { // Munge the data
  if(d.length < 3) { return; }
  // Force the columns to be numbers and add a difference
  var label, a, b, diff, r;
  label = d[0].trim();
  a = d[1];
  b = d[2];
  diff = b - a;

  r = { label: label, a: a, b: b, diff: diff }
  // Keep track of the positive and negative totals
  if(a >= 0) {
    data.a_positive.push(r);
    a_positive_total = a_positive_total + a;
  } else {
    data.a_negative.push(r);
    a_negative_total = a_negative_total + a;
  };

  r = { label: label, a: a, b: b, diff: diff }
  if(b >= 0) {
    data.b_positive.push(r);
    b_positive_total = b_positive_total + b;
  } else {
    data.b_negative.push(r);
    b_negative_total = b_negative_total + b;
  };

  r = { label: label, a: a, b: b, diff: diff }
  if(diff > 0) {
    data.diff_positive.push(r);
    diff_positive_total = diff_positive_total + diff;
  } else {
    data.diff_negative.push(r);
    diff_negative_total = diff_negative_total + diff;
  }

  return r;
};

var left;
var right;
var left_period = "npv";
var right_period = "npv";

function reformat_data() {
    combined_data = d3.map();
    a_name = left.name+" "+left_period;
    b_name = right.name+" "+right_period;

    data = {
      a_negative: [],
      a_positive: [],
      diff_positive: [],
      diff_negative: [],
      b_positive: [],
      b_negative: []
    } 

    a_positive_total = 0; 
    b_positive_total = 0; 
    a_negative_total = 0; 
    b_negative_total = 0;
    diff_positive_total = 0;
    diff_negative_total = 0;

    number_of_columns = 0;

    select_left_data();
    select_right_data();
    do_maths_on_each_element();
    calculate_totals();
};

var left_column = 1;
var right_column = 2;

function select_left_data() {
  select_data(left.processes_by_year, left_period, left_column);
}

function select_right_data() {
  select_data(right.processes_by_year, right_period, right_column);
};

function select_data(data, period, column) {
  d3.map(data).forEach(function(process_name, data_by_year) {
    var value = value_for_period(data_by_year, period);
    var name = aggregated_name_for(process_name);
    var existing_value = existing_value_for(name);
    existing_value[column] = existing_value[column] + value;
    set_combined_data(existing_value);
  });
};

function do_maths_on_each_element() {
  combined_data.forEach(function(process_name, d) { add_data_point(d); });
};

function calculate_totals() {
  b_total_over_a_total = (b_positive_total + b_negative_total) / (a_positive_total + a_negative_total);
  diff_over_a_total = ( -diff_negative_total ) / (a_positive_total + a_negative_total);
}

function value_for_period(data_by_period, period) {
  var value = data_by_period[period] || 0;
  value = convert_value(value, period);
  return value;
}

// This can be overriden to mess with the axes
function convert_value(value, period) {
  return value;
};

function aggregated_name_for(process_name) {
  return process_name;
}

function existing_value_for(process_name) {
  return combined_data.get(process_name) || default_combined_value(process_name);
};

function default_combined_value(process_name) {
  return [process_name, 0, 0];
};

function set_combined_data(data) {
  combined_data.set(data[0], data);
};

function proceed() {
  if(all_files_loaded()) {
    reformat_data();
    set_scales();
    position_data();
    draw();
  }
};

function all_files_loaded() {
  return left_case_loaded_flag && right_case_loaded_flag && code_to_name_lookup_loaded_flag && code_to_sector_lookup_loaded_flag;
}

function case_loaded(individual_case) {
  cases.push(individual_case);
}

function load_left_case() {
  d3.json(url_for_case_data(left_case_name), function(d) {
    left = d;
    left_case_loaded_flag = true;
    proceed();
  });
}

function load_right_case() {
  d3.json(url_for_case_data(right_case_name), function(d) {
    right = d;
    right_case_loaded_flag = true;
    proceed();
  });
}

function url_for_case_data(case_name) {
  return case_name + "/detailed-costs.json";
}

function go() {
  settings = window.location.hash.slice(1).split(',');
  list_of_cases = settings.slice(0,2);
  left_case_name = settings[0];
  right_case_name = settings[1];
  left_period = settings[2];
  right_period = settings[3];
  load_left_case();
  load_right_case();
};

function capitalize(string) {
  return string[0].toUpperCase() + string.slice(1);
};

var y_axis_label = "";

function y_axis_label_text() {
  return y_axis_label;
};

d3.select("#chart_link").on("click", function() {
  window.location = "sectoral-costs.html"+window.location.hash;
});
