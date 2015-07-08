require_relative 'gdx'

class ExtractHeatingFlows

  PROCESS_NAME_REGEX = /^(.*?)\d*$/ # This is used to trim the numbers off the end of process names
  HEATING_COMMODITIES = %w{ EA NA HC HS FC FS }.map do |type_of_house| 
                          %w{ RHEATPIPE- RHCSV-RH RHUFLOOR- RHSTAND- }.map do |type_of_heating| 
                            type_of_heating+type_of_house 
                          end
                        end.flatten +
                        %w{ HL HH SCH }.map do |type_of_service|
                          %w{ CSVDMD DELVRAD DELVUND DELVAIR DELVSTD }.map do |type_of_heating_or_cooling|
                            type_of_service+type_of_heating_or_cooling
                          end
                        end.flatten

  attr_accessor :gdx
  attr_accessor :scenario_name
  attr_accessor :results
  attr_accessor :commodities_included
  
  def extract_results
    extract_heating_flows
  end

  def extract_heating_flows
    extract_all_flows
    filter_heating_flows
    aggregate_heating_flows
    results
  end

  private

  attr_accessor :flows_out

  def extract_all_flows
    @flows_out = gdx.symbol(:F_OUT)
  end

  def filter_heating_flows
    @flows_out = flows_out.select { |flow| include_commodity?(flow[:c]) }
  end

  def include_commodity?(commodity)
    HEATING_COMMODITIES.include?(commodity)
  end

  def aggregate_heating_flows
    processes_by_year = results[:processes_by_year]
    flows_out.each do |flow|
      process_name = combined_process_name(flow[:p])
      commodity_name = flow[:c]
      value = flow[:val] / 3.6 # to get from PJ to TWh
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
