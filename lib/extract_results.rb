require 'ostruct'
require 'json'
require 'fileutils'
require 'pathname'

require_relative 'extract_overall_cost_and_emissions'
require_relative 'extract_build_rates'
require_relative 'extract_detailed_costs'
require_relative 'extract_detailed_emissions'
require_relative 'extract_electricity_flows'
require_relative 'extract_transport_flows'
require_relative 'extract_heating_flows'

class ExtractResults

  attr_accessor :settings

  def initialize(settings = OpenStruct.new)
    @settings = settings
  end

  def write_results(gdx_file_name)
    log.info "Writing results for #{gdx_file_name}"

    gdx = Gdx.new(gdx_file_name)
    name = File.basename(gdx_file_name, '.*')

    Pathname.new(File.join(settings.results_folder, name)).mkpath

    log.info "Creating cost-emissions scatter for #{gdx_file_name}"
    extract_and_write_result name, gdx, ExtractOverallCostAndEmissions.new, "costs-and-emissions-overview.json"

    log.info "Creating build rate charts for #{gdx_file_name}"
    extract_and_write_result name, gdx, ExtractBuildRates.new, "build-rates.json"

    log.info "Creating flying brick cost charts for #{gdx_file_name}"
    extract_and_write_result name, gdx, ExtractDetailedCosts.new, "detailed-costs.json"

    log.info "Creating detailed emissions charts for #{gdx_file_name}"
    extract_and_write_result name, gdx, ExtractDetailedEmissions.new, "detailed-emissions.json"

    log.info "Creating electricity charts for #{gdx_file_name}"
    extract_and_write_result name, gdx, ExtractElectricityFlows.new, "electricity-flows.json"

    log.info "Creating transport charts for #{gdx_file_name}"
    extract_and_write_result name, gdx, ExtractTransportFlows.new, "transport-flows.json"

    log.info "Creating heating charts for #{gdx_file_name}"
    extract_and_write_result name, gdx, ExtractHeatingFlows.new, "heating-flows.json"

    log.info "Creating the index for #{gdx_file_name}"
    write_index_txt
  end

  def create_results_folder_if_doesnt_exist
    return false if File.exist?(settings.results_folder)
    log.info "Creating a results folder: #{File.expand_path(settings.results_folder)}"
    Pathname.new(settings.results_folder).mkpath
    true
  end

  def copy_across_html_if_no_index_html
    return false if File.exist?(File.join(settings.results_folder, 'index.html'))
    log.info "Copying accross html"
    FileUtils.cp_r(Dir.glob(File.join(File.dirname(__FILE__),"..","results-template",'*')),settings.results_folder)
  end

  def extract_and_write_result(name, gdx, extractor, filename)
    extractor.gdx = gdx
    extractor.scenario_name = name
    results = extractor.extract_results
    write_result name, filename, results.to_json
  end

  def write_result(case_name, result, data)
    File.open(File.join(settings.results_folder, case_name, result), 'w') do |f|
      f.puts data
    end
  end

  # This ensures that index.txt in the results folder has ALL the results
  # not just those produced in this run
  # FIXME: Race condition?
  def write_index_txt
    # Case directories are the ones with json in them
    case_directories = Dir[File.join(settings.results_folder,'*/*.json')].map { |f| File.basename(File.dirname(f)) }.uniq
    File.open(File.join(settings.results_folder, "index.txt"), 'w') { |f| f.puts case_directories.join("\n") }
  end

  def log
    settings.log
  end

end
