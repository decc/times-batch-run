var scenario_names = scenario_code_to_name_lookup();
var all_cases = d3.map();
var data = [];
var scenarios = [];
var year_to_display = '2030'
var chart_width = d3.select("#chart").node().clientWidth;
var chart_height = Math.ceil(chart_width * 0.75);
var chart = scatterchart(chart_width, chart_height);
var selected_scenarios = d3.set();
var cost_format = d3.format(",.1f");
var emissions_format = d3.format(",.0f");
var cost_label = "Total Cost £trn (2010-2050, discounted)"
var x_extent = [0,5000];
var y_extent = [0,20];

function go() {
  load_all_cases(all_cases_loaded);
};

function all_cases_loaded() {
  read_user_choices_from_hash();
  extract_scenarios_from_data();
  calculate_chart_dimensions();
  redraw();
}

function redraw() {
  update_hash();
  filter_cases_to_display();
  draw_chart();
  draw_scenario_table();
  draw_case_table();
};

function load_all_cases(next_function) {
  var list_of_case_names;
  var index_file = 'index.txt';
  var data_file_name = "/costs-and-emissions-overview.json"; 
  var line_endings = /[\r\n]+/;
  
  load_list_of_cases();

  function load_list_of_cases() {
    d3.text(index_file, list_of_cases_loaded);
  };

  function list_of_cases_loaded(list_of_cases) {
    list_of_case_names = clean_list(list_of_cases);
    list_of_case_names.forEach(load_case);
  };

  function clean_list(list) {
    return list
      .split(line_endings)
      .filter(line_not_empty)
      .filter(line_not_comment);
  };
  
  function line_not_empty(line) { return line.trim().length != 0 };

  function line_not_comment(line) { return line.trim()[0] != "#" };

  function load_case(case_name) {
    d3.json(case_name+data_file_name, case_loaded);
  };

  function case_loaded(individual_case) {
    store_case(individual_case);
    if(all_cases_have_been_loaded()) { finished() };
  };

  function store_case(individual_case) {
    all_cases.set(individual_case.name, individual_case);
  };

  // FIXME: How do we deal with failiures to load cases?
  function all_cases_have_been_loaded() {
    return all_cases.size() == list_of_case_names.length;
  };

  function finished() {
    next_function();
  };
};

function extract_scenarios_from_data() {
  var cases_by_scenario = d3.map();

  // Load up the scenarios map with every case in that scenario
  all_cases.forEach(function(name, d) {
    d.scenarios.forEach(function(s) {
      var cases_for_scenario = cases_by_scenario.get(s) || []; // Existing cases for scenario, or create a new array
      cases_for_scenario.push(d);
      cases_by_scenario.set(s, cases_for_scenario);
    });
  });

  // Then remove all the scenarios which are the same in every case
  cases_by_scenario.forEach(function(scenario, list_of_cases) {
    if(list_of_cases.length < all_cases.size()) {
      scenarios.push(scenario);
    }
  });
  scenarios.sort(function(a,b) { return d3.ascending(scenario_names(a),scenario_names(b)) });

}

function calculate_chart_dimensions() {
  y_extent = [0, d3.max(all_cases.values(), function(d) { return d.cost; })]
  x_extent = d3.extent(all_cases.values(), function(d) { return d.budget[year_to_display]; })
  y_extent[1] = y_extent[1] * 1.1;
  var space = (x_extent[0] + x_extent[1]) * 0.05;
  x_extent[0] = x_extent[0] - space;
  x_extent[1] = x_extent[1] + space;
};

function filter_cases_to_display() {
  data = all_cases.values().filter(case_has_selected_scenarios);
}

function case_has_selected_scenarios(d) {
  var in_case = d.scenarios;
  var selected = selected_scenarios.values();
  for(var i=0; i<selected.length; i++) {
    if(in_case.indexOf(selected[i]) == -1) { return false }
  };
  return true;
}

function read_user_choices_from_hash() {
  hash = window.location.hash.slice(1).split(',');
  hash.forEach(function(scenario) {
    scenario = scenario.trim();
    if(scenario != "") {
      selected_scenarios.add(scenario);
    }
  });
};

function update_hash() {
   window.location = "#"+hash_code_for_selected_scenarios();
};

function hash_code_for_selected_scenarios() {
  if(selected_scenarios.empty()) { return ""; };
  return selected_scenarios.values().join(",");
};

function draw_scenario_table() {
  var split_scenarios = divide_array_in_two(scenarios); 

  var filter_tables = d3.select("#filter").selectAll("table.filter_table")
  	.data(split_scenarios);

  var new_filter_table_header = filter_tables.enter().append("table")
    .attr("class",filter_table_class).append("tr");

  new_filter_table_header.append("th").html("&lsquo;What if&rsquo;");

  filter_tables.exit().remove();

  var scenario_rows = filter_tables.selectAll("tr.scenario").data(Object);

  var new_scenario_row = scenario_rows.enter()
    .append("tr")
    .attr("class", filter_table_row_class);

  new_scenario_row.append("td").attr("class", "name");

  scenario_rows.select("td.name")
    .text(function(d) { return scenario_names(d); });

  scenario_rows.on("click", toggle_selected_scenario);
  scenario_rows.on("mouseover", highlight_cases_with_scenario);
  scenario_rows.on("mouseout", unhighlight_cases_with_scenario);
};

function filter_table_class() {
  if(selected_scenarios.empty()) {
    return "filter_table";
  } else {
    return "filter_table permanent_filter_on";
  }
}

function filter_table_row_class(s) {
  if(selected_scenarios.has(s)) {
    return "scenario s"+s+" permanently_selected";
  } else {
    return "scenario s"+s+"";
  }
}

function toggle_selected_scenario(d) {
  if(selected_scenarios.has(d)) { 
    selected_scenarios.remove(d);
  } else {
    selected_scenarios.add(d);
  }
  redraw();
};

function highlight_cases_with_scenario(s) {
  var table = d3.selectAll('table.filter_table');
  table.classed("filter_on",true);

  d3.select(this).classed("selected", true);

  d3.selectAll(".s"+s).classed("selected", true);
};

function unhighlight_cases_with_scenario(s) {
  d3.selectAll(".selected").classed("selected", false);
  d3.selectAll(".filter_on").classed("filter_on", false);
};

function divide_array_in_two(array) {
  var break_point = Math.ceil(array.length/2);
  return [array.slice(0,break_point), array.slice(break_point)];
};

function draw_chart() {
  chart.max_y_to_show = 

  // Now add the chart to the screen
  instcap = d3.select("body").selectAll('#chart')
    .datum(data)
    .call(chart);
};

function scatterchart(width, height) {

  function emissions_to_plot(d) {
	  return d.budget[year_to_display];
  }

  var margin = {top: 20, right: 50, bottom: 50, left: 50};
  var x = d3.scale.linear();
  var y = d3.scale.linear();

  var xAxis = d3.svg.axis()
    .tickFormat(d3.format("0f"))
    .scale(x)
    .orient("bottom");

  var yAxis = d3.svg.axis()
    .scale(y)
    .orient("left");

  var cross_hair_label_format = d3.format(".1f");

  // Returns the Carbon Budget that a particular year is in

  function chart(selection) {
    selection.each(function(data) {
        if(data == undefined) { return; }

        var svg = d3.select(this).selectAll("svg").data([data]);

        var new_svg = svg.enter().append("svg").append("g").attr("class", "canvas");

        new_svg.append("g").attr("class", "cases");
        new_svg.append("g").attr("class", "x axis");
        new_svg.append("g").attr("class", "y axis");
        new_svg.append("text")
          .attr('y', -7)
          .attr('x', -20)
          .attr("class", "y_axis_label")
          .text(cost_label)
        new_svg.append("text")
          .attr("text-anchor", "middle")
          .attr("class", "x_axis_label");

        new_svg.append("line").attr("id","line_to_y_axis");
        new_svg.append("line").attr("id","line_to_x_axis");
        new_svg.append("text").attr("id","x_value_of_case");
        new_svg.append("text").attr("id","y_value_of_case");
        new_svg.append("text").attr("id","name_of_case");

        // Update the outer dimensions.
        svg.attr("width", width)
          .attr("height", height);

        // Update the inner dimensions.
        var g = svg.select("g.canvas")
          .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

        // Update the y-axis
        //  y
        //    .domain()
         //   .range([height - margin.top - margin.bottom, 0])
         //   .nice();
        //} else {
          y
            .domain(y_extent)
            .range([height - margin.top - margin.bottom, 0])
            .nice();

        svg.select(".y.axis")
          .call(yAxis);

        // Update the x-axis
        x
          .domain(x_extent)
          //.domain(d3.extent(data, function(d) { return emissions_to_plot(d)}))
          .range([0, width - margin.left - margin.right])
          .nice();

        svg.select(".x.axis")
          .attr("transform", "translate(0," + y.range()[0] + ")")
          .call(xAxis);

        svg.select(".x_axis_label")
          .attr("transform", "translate(0," + (y.range()[0]+30) + ")")
          .attr("x", d3.mean(x.range()))
          .text(emissions_label());

        // Update the title
        // FIXME: Shouldn't really be done in this routine
        d3.select("h1#title").text("Level of Carbon Budget "+carbon_budget_number(year_to_display)+" against cost");

        // Update the cases
        var cases = g.select(".cases").selectAll("g.case")
          .data(Object, function(d) { return d.name; });

        var new_cases = cases.enter()
          .append("g")
          .attr("class", "case");

        cases.exit().remove();

        new_cases.append("circle")
            .attr("r", 5)
            .attr("id", function(d) { return d.name })
            .attr("class", function(d) { return "case "+d.scenarios.map(function(s) { return "s"+s; }).join(" ") }); // Prepend s, becausee some scenarios start with a number, which isn't valid as a css class name

        cases.selectAll("circle")
          .attr("cx", function(d) { return x(emissions_to_plot(d)); })
          .attr("cy", function(d) { return y(d.cost); });

        // Add the interactivity

        d3.selectAll("g.case")
          .on("mouseover", function(selected_case) {
            d3.select(this).classed("selected", true);

            var table = d3.selectAll('table.filter_table');
            table.classed("filter_on",true);

            selected_case.scenarios.forEach(function(s) {
              table.selectAll("tr.s"+s).classed("selected", true);
            });

            update_crosshairs(selected_case);
          })
        .on("click", function(selected_case) {
          window.location = "case.html#"+selected_case.name;
        }).on("mouseout", function() {
          d3.selectAll(".selected").classed("selected", false);
          d3.selectAll(".filter_on").classed("filter_on", false);
          hide_crosshairs();
        });
    });
  };

  chart.year_to_display = function(_) {
    if (!arguments.length) return year_to_display;
    year_to_display = _;
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

  chart.max_y_to_show = function(_) {
    if (!arguments.length) return max_y_to_show;
    max_y_to_show = _;
    return chart;
  }

  function update_crosshairs(target) {
    // Draw the lines to each axis
    d3.select("#line_to_y_axis")
      .classed("show_crosshairs", true)
      .attr("x1", x.range()[0])
      .attr("y1", y(target.cost))
      .attr("x2", x(emissions_to_plot(target))-3)
      .attr("y2", y(target.cost));

    d3.select("#line_to_x_axis")
      .classed("show_crosshairs", true)
      .attr("x1", x(emissions_to_plot(target)))
      .attr("y1", y(target.cost)+3)
      .attr("x2", x(emissions_to_plot(target)))
      .attr("y2", y.range()[0]);

    d3.select("#x_value_of_case")
      .classed("show_crosshairs", true)
      .attr("x", x(emissions_to_plot(target)))
      .attr("y", y.range()[0]-2)
      .text(cross_hair_label_format(emissions_to_plot(target)));

    d3.select("#y_value_of_case")
      .classed("show_crosshairs", true)
      .attr("x", x.range()[0]+2)
      .attr("y", y(target.cost)-2)
      .text(cross_hair_label_format(target.cost));

    d3.select("#name_of_case")
      .classed("show_crosshairs", true)
      .attr("x", x(emissions_to_plot(target))+5)
      .attr("y", y(target.cost)-5)
      .text(target.name);

    return chart;
  }

  function hide_crosshairs(_) {
    d3.selectAll(".show_crosshairs").classed("show_crosshairs", false);
    return chart;
  }

  return chart;
}

function emissions_label() {
 return "Level of Carbon Budget "+carbon_budget_number(year_to_display)+" (MtCO2e in "+year_to_display+"x5)";
}

function draw_case_table() {

  var table_data = data;
  table_data.sort(function(a,b) { return d3.descending(a.cost, b.cost) });

  if(table_data.length > 200) {
    table_data = table_data.slice(0,100).concat(table_data.slice(table_data.length-100));
    d3.select("overflow_message").classed("hidden",false);
  } else {
    d3.select("overflow_message").classed("hidden",true);
  }

  var case_tables = d3.select("#cases").selectAll("table.case_table")
  	.data([data]);

  var new_case_table_header = case_tables.enter().append("table")
    .attr("class",'case_table').append("tr");

  new_case_table_header.append("th").html("Scenario");
  new_case_table_header.append("th").html(cost_label);
  new_case_table_header.append("th").html(emissions_label());

  var case_rows = case_tables.selectAll("tr.case").data(Object);

  var new_case_row = case_rows.enter()
    .append("tr");

  new_case_row.append("td").append("a").attr("class", "name");
  new_case_row.append("td").append("a").attr("class", "cost");
  new_case_row.append("td").append("a").attr("class", "budget_emissions");

  case_rows.select(".name")
    .text(function(d) { return d.name; })
    .attr("href", function(d) { return "case.html#"+d.name; });

  case_rows.select(".cost")
    .text(function(d) { return cost_format(d.cost); })
    .attr("href", function(d) { return "sectoral-costs.html#"+d.name+","+d.name+",2015,2050"; });

  case_rows.select(".budget_emissions")
    .text(function(d) { return emissions_format(d.budget[year_to_display]); })
    .attr("href", function(d) { return "sectoral-emissions.html#"+d.name+","+d.name+",2015,"+year_to_display; });

  case_rows.exit().remove();
};

function scenario_code_to_name_lookup() {
  var codes = d3.map();

  d3.tsv("scenario_names.tsv").get(function(error, rows) {
      if (error) return console.warn(error);

      rows.forEach(function(row) {
        codes.set(row['Code'], row['Name']);
        });
      });

  function lookup(code) {
    return codes.get(code) || code;
  };

  return lookup;
}

function carbon_budget_number(year) {
  return Math.floor((year-2008)/5)+1;
}
