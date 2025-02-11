#!/usr/bin/env ruby

require 'open-uri'
require 'JSON'
require 'csv'
require 'FileUtils'

# This should be externalized somehow as a param
file_name = 'active.txt'
target_version = '2.401.3.4'
target_csv = 'plugins_single_target.csv'

# Downloading files
uri, filename)
  puts "Starting HTTP download for: " + uri.to_s
filename.to_s, "wb") do |saved_file|
    # the following "open" is provided by open-uri
uri.to_s, "rb") do |read_file|
read_file.read)
    end
  end
  puts "Stored download as " + filename + "."
end

# Validate whether or not it's in CAP
plugin_name, json)
  begin
    checker = json["offeredEnvelope"]["plugins"][plugin_name]["artifactId"]
    return true
  rescue => e
    return false
  end
end

# Downloads JSON files from CB UC
version)
  # Check to see if we've already downloaded this JSON; download if not
"uc-#{version}.json")
"https://jenkins-updates.cloudbees.com/update-center.json?version=#{version}", "uc-#{version}.json")
'sed', '-i', 'uc.bak', '1d;$d', "uc-#{version}.json")
  else
    puts "Skipping download of JSON for version #{version} as it already has been downloaded."
  end 
end

notes, new_note)
  notes = notes.empty? ? new_note : "#{notes}\n#{new_note}"
  puts new_note
  return notes
end

# Download the target version JSON
target_version)

# Read the JSON files
"uc-#{target_version}.json"))

# Delete the CSV before starting.
target_csv)

# Open CSV for writing
target_csv, "w")

# CSV headers
headers = ["plugin_id", "installed_ver", "new_ver_#{target_version}", "req_core_#{target_version}", "cap_#{target_version}", "in_uc_#{target_version}", "notes"]

# Add headers
csv << headers

# Get file content to string
file_name)

# Set our plugin_info array to empty
plugin_info = []

# TODO: Loop plugin entries.
plugin_list.each_line do |plugin|
  # This will determine whether we're going to analyze any deeper
  continue_target = true

  target_plugin_ver = ""
  target_required_core = ""

  # Checkers for Update Center
  in_uc_target = true

  # Checkers for CAP
  in_cap_target = true
  
  notes = ""

  # Split each entry into two parts from the colon
":")
  p_id = p_split[0]
  p_ver = p_split[1]

  # Check if target version is in UC
  begin
    target_plugin_ver = target_json["plugins"][p_id]["version"]
    target_required_core = target_json["plugins"][p_id]["requiredCore"]
  rescue => e
    temp_note = "[#{target_version}][NOT_IN_UC] Plugin #{p_id} not found in Update Center for #{target_version}."
notes, temp_note)
    in_uc_target = false
    continue_target = false
  end

  # Check if target version is in CAP
  begin
    target_plugin_ver = target_json["offeredEnvelope"]["plugins"][p_id]["version"]
  rescue => e
    temp_note = "[#{target_version}][NOT_IN_CAP] Plugin #{p_id} not found in CloudBees Assurance Program for #{target_version}."
notes, temp_note)
    in_cap_target = false
  end

  # ====================================
  # Start analysis of versions and cores
  # ====================================
continue_target)
target_plugin_ver.to_s > p_ver.chomp.to_s) ? target_plugin_ver.to_s : "Up-to-Date"
target_required_core < "2.277.2.1")
notes, "Target Version required Core pre-dates Tables-to-DIVs change. Check this plugin for compatibility!")
    end
  end

  # Output our CSV to a file
  csv << [p_id, p_ver.chomp, target_ver_diff.to_s, target_required_core, in_cap_target.to_s, in_uc_target.to_s, notes]
end

# Close the CSV for writing
csv.close