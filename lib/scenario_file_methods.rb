module ScenarioFileMethods
  def nil_scenario_file?(scenario_name)
    scenario_name.strip =~ /^nil$/i
  end

  def scenario_filename_from_name(scenario_name)
    "#{scenario_name.strip}.dd"
  end

  def scenario_file_exists?(scenario_name)
    return true if nil_scenario_file?(scenario_name)
    scenario_filename = scenario_filename_from_name(scenario_name)
    places_to_look_for_scenario_files.any? do |directory|
      File.exist?(File.join(directory, scenario_filename))
    end
  end
end
