require 'ostruct'
require 'pathname'

class RunOptimisation

  attr_accessor :settings

  def initialize(settings = OpenStruct.new)
    @settings = settings
  end

  def check_files_needed_to_run_times_are_available!
    files_to_check = {
      TIMES_source_folder: times_source_folder,
      GAMS_working_folder: path_to_gams_working_folder,
      GDX_save_folder: gdx_save_folder,
      VT_GAMS_script: vt_gams,
      times2veda_script: times_2_veda
    }

    files_to_check.each do |name, location|
      next if File.exist?(location)
      log.fatal "Can't find #{name.to_s.gsub('_',' ')} at #{File.expand_path(location)}"
      exit
    end
  end  
  
  def run_case(case_name)
    log.info "Looking for #{case_name}.RUN"
    unless File.exist?("#{case_name}.RUN")
      log.fatal "Can't find #{File.expand_path("#{case_name}.RUN")}"
      exit
    end
    log.info "Executing #{case_name}"
    output_gdx_name = File.join(gdx_save_folder, case_name)

    `#{vt_gams} #{case_name} #{settings.times_source_folder} #{output_gdx_name.gsub('/','\\')}`

    if Gdx.new(case_name).valid?
      names_of_all_the_cases_that_solved.push(case_name)
      log.puts "Putting #{case_name} into VEDA"
      `GDX2VEDA #{output_gdx_name.gsub('/','\\')} #{times_2_veda} #{case_name} > #{case_name}`
      return output_gdx_name+".gdx"
    else
      log.error "Case #{case_name} failed to solve - couldn't find valid #{output_gdx_name}.gdx"
      return nil
    end
  end

  private

  def log
    settings.log
  end

  def veda_fe_folder
    Pathname.getwd.parent
  end

  def times_source_folder
    veda_fe_folder + settings.times_source_folder
  end

  def path_to_gams_working_folder
    veda_fe_folder + settings.gams_working_folder
  end

  def gdx_save_folder
    path_to_gams_working_folder + settings.gams_save_folder
  end

  def vt_gams
    times_source_folder + settings.vt_gams
  end

  def times_2_veda
    times_source_folder + "times2veda.vdd"
  end


end
