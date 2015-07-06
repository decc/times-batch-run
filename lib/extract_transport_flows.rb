require_relative 'gdx'

class ExtractTransportFlows

  PROCESS_NAME_REGEX = /^(.*?)\d*$/ # This is used to trim the numbers off the end of process names
  TRANSPORT_COMMODITIES = %w{ TC TB TL TW TH} # Just the ones that have Bvkm

  attr_accessor :gdx
  attr_accessor :scenario_name
  attr_accessor :results
  attr_accessor :commodities_included
  
  def extract_results
    extract_transport_flows
  end

  def extract_transport_flows
    extract_all_flows
    filter_transport_flows
    aggregate_transport_flows
    results
  end

  private

  attr_accessor :flows_out

  def extract_all_flows
    @flows_out = gdx.symbol(:F_OUT)
  end

  def filter_transport_flows
    flows_out.delete_if { |flow| exclude_commodity?(flow[:c]) }
  end

  def exclude_commodity?(commodity)
    !TRANSPORT_COMMODITIES.include?(commodity)
  end

  def aggregate_transport_flows
    processes_by_year = results[:processes_by_year]
    flows_out.each do |flow|
      process_name = combined_process_name(flow[:p])
      commodity_name = flow[:c]
      value = flow[:val]
      year = flow[:t]
      processes_by_year[process_name][year] += value
    end
  end

  def results
    @results ||= {
      :name => scenario_name,
      :processes_by_year =>  Hash.new() { |hash, new_key| hash[new_key] = Hash.new(0) }
    }
  end
  
  # Strips the trailing 00 01 02 off the end of process names to group them a bit
  def combined_process_name(process_name)
    process_name[PROCESS_NAME_REGEX,1]
  end
  
end
