require_relative 'gdx'
require 'json'

class ExtractEnergyFlows

  YEARS = [2010, 2011, 2012, 2015, 2020, 2025, 2030, 2035, 2040, 2045, 2050, 2055, 2060] # The gdx data doesn't include zero values, so we have to include them manually. <sigh>

  attr_accessor :gdx
  attr_accessor :scenario_name
  
  def extract_results
    initialize_values
    get_commodity_group_clasification
    extract_flows_in_and_out
    filter_non_energy_flows
    combine_flows_in_an_out_into_flows
    return flows_as_json
  end

  private

  attr_accessor :flows_in
  attr_accessor :flows_out
  attr_accessor :flows 
  attr_accessor :commodity_group

  def initialize_values
    @flows = new_flow_hash
    @commodity_group = {}
  end

  def get_commodity_group_clasification
    gdx.symbol(:COM_TMAP).each do |mapping|
      commodity_group[mapping[:com]] = mapping[:com_type]
    end
  end

  def extract_flows_in_and_out
    @flows_in = gdx.symbol(:F_IN)
    @flows_out = gdx.symbol(:F_OUT)
  end

  def filter_non_energy_flows
    @flows_in = filter_non_energy_flows_for(@flows_in)
    @flows_out = filter_non_energy_flows_for(@flows_out)
  end

  def filter_non_energy_flows_for(flows)
    flows.select { |flow| commodity_group[flow[:c]] == "NRG" }
  end

  def combine_flows_in_an_out_into_flows
    @flows_in.each do |flow|
      add_flow(@flows, "C-"+flow[:c], "P-"+flow[:p], flow[:t], flow[:val] / 3.6)  # 3.6 to get from PJ to TWh
    end
    @flows_out.each do |flow|
      add_flow(@flows, "P-"+flow[:p], "C-"+flow[:c],  flow[:t], flow[:val] / 3.6)
    end
  end

  def each_flow
    flows.each do |from, to_hash|
      to_hash.each do |to, year_hash|
        year_hash.each do |year, value|
          yield from, to, year, value
        end
      end
    end
  end

  def new_flow_hash
    Hash.new { |from_hash, from| from_hash[from] = Hash.new { |to_hash,to| to_hash[to] = Hash.new { |year_hash, year| year_hash[year] = 0 }}}
  end

  def add_flow(hash, from, to, year, value)
    hash[from][to][year] = hash[from][to][year] + value
  end

  def flows_as_table
    header = ["From", "To"].concat(YEARS)
    table = [header]
    flows.each do |from, to_hash|
      to_hash.each do |to, year_hash|
        table.push( [from, to].concat(YEARS.map { |year| year_hash[year] }) )
      end
    end
    return table
  end

  def flows_as_json
    YEARS.map { |year| { name: scenario_name, year: year, flows: flows_as_json_for_year(year) } }
  end

  def flows_as_json_for_year(chosen_year)
    index = -1;
    nodes = Hash.new { |hash, name| index +=1; hash[name] = index  }
    links = [];
    each_flow do |from, to, year, value|
      next unless year == chosen_year
      next unless nodes[from]
      next unless nodes[to]
      links << { source: nodes[from], target: nodes[to], value: value }
    end
    { nodes: nodes.keys.map { |name| {name: name} }, links: links }
  end

  def tsv(array_of_arrays)
    array_of_arrays.map { |array| array.join("\t") }.join("\n")
  end

end

if __FILE__ == $0
  gdx = Gdx.new(ARGV[0])
  extractor = ExtractFlows.new
  extractor.gdx = gdx
  extractor.extract_results
end
