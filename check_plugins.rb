#!/usr/bin/env ruby

require 'open-uri'
require 'JSON'
require 'csv'

# This should be externalized somehow as a param
file_name = 'active.txt'
current_version = '2.401.3.4'
target_version = '2.462.1.3'

# Downloading files
def http_download_uri(uri, filename)
  puts "Starting HTTP download for: " + uri.to_s
  File.open(filename.to_s, "wb") do |saved_file|
    # the following "open" is provided by open-uri
    open(uri.to_s, "rb") do |read_file|
      saved_file.write(read_file.read)
    end
  end
  puts "Stored download as " + filename + "."
end

# Validate whether or not it's in CAP
def check_if_cap(plugin_name, json)
  begin
    checker = json["offeredEnvelope"]["plugins"][plugin_name]["artifactId"]
    return true
  rescue => e
    return false
  end
end

# Downloads JSON files from CB UC
def download_json(version)
  # Check to see if we've already downloaded this JSON; download if not
  unless File.exists?("uc-#{version}.json")
    http_download_uri("https://jenkins-updates.cloudbees.com/update-center.json?version=#{version}", "uc-#{version}.json")
    trimmed = system('sed', '-i', 'uc.bak', '1d;$d', "uc-#{version}.json")
  else
    puts "Skipping download of JSON for version #{version} as it already has been downloaded."
  end 
end

def add_note(notes, new_note)
  notes = notes.empty? ? new_note : "#{notes}\n#{new_note}"
  puts new_note
  return notes
end

# Startup ASCII ftw
File.foreach("analysis.txt") { |line| puts line }

# Download the target version JSON
download_json(target_version)
# Download the JSON for the current version
download_json(current_version)

# Read the JSON files
target_json = JSON.parse(File.read("uc-#{target_version}.json"))
current_json = JSON.parse(File.read("uc-#{current_version}.json"))

# Delete the CSV before starting.
File.delete("plugin_updates.csv") if File.exist?("plugin_updates.csv")

# Open CSV for writing
csv = CSV.open("plugin_updates.csv", "w")

# CSV headers
headers = ["plugin_id", "installed_ver", "new_ver_#{current_version}", "new_ver_#{target_version}", "req_core_#{target_version}", "cap_#{current_version}", "cap_#{target_version}", "in_uc_#{current_version}", "in_uc_#{target_version}", "notes"]

# Add headers
csv << headers

# Get file content to string
plugin_list = File.read(file_name)

# Set our plugin_info array to empty
plugin_info = []

# TODO: Loop plugin entries.
plugin_list.each_line do |plugin|
  # This will determine whether we're going to analyze any deeper
  continue_target = true
  continue_current = true

  target_plugin_ver = ""
  target_required_core = ""
  current_plugin_ver = ""
  current_required_core = ""

  # Checkers for Update Center
  in_uc_current = true
  in_uc_target = true

  # Checkers for CAP
  in_cap_current = true
  in_cap_target = true
  
  notes = ""

  # Split each entry into two parts from the colon
  p_split = plugin.split(":")
  p_id = p_split[0]
  p_ver = p_split[1]

  # Check if target version is in UC
  begin
    target_plugin_ver = target_json["plugins"][p_id]["version"]
    target_required_core = target_json["plugins"][p_id]["requiredCore"]
  rescue => e
    temp_note = "[#{target_version}][NOT_IN_UC] Plugin #{p_id} not found in Update Center for #{target_version}."
    notes = add_note(notes, temp_note)
    in_uc_target = false
    continue_target = false
  end

  # Check if current version is in UC
  begin
    current_plugin_ver = current_json["plugins"][p_id]["version"]
    current_required_core = current_json["plugins"][p_id]["requiredCore"]
  rescue => e
    temp_note = "[#{current_version}][NOT_IN_UC] Plugin #{p_id} not found in Update Center for #{current_version}."
    notes = add_note(notes, temp_note)
    in_uc_current = false
    continue_current = false
  end

  # Check if target version is in CAP
  begin
    target_plugin_ver = target_json["offeredEnvelope"]["plugins"][p_id]["version"]
  rescue => e
    temp_note = "[#{target_version}][NOT_IN_CAP] Plugin #{p_id} not found in CloudBees Assurance Program for #{target_version}."
    notes = add_note(notes, temp_note)
    in_cap_target = false
  end

  # Check if current version is in CAP
  begin
    current_plugin_ver = current_json["offeredEnvelope"]["plugins"][p_id]["version"]
  rescue => e
    temp_note = "[#{current_version}][NOT_IN_CAP] Plugin #{p_id} not found in CloudBees Assurance Program for #{current_version}."
    notes = add_note(notes, temp_note)
    in_cap_current = false
  end

  # ====================================
  # Start analysis of versions and cores
  # ====================================

  if (continue_current)
    current_ver_diff = (current_plugin_ver.to_s > p_ver.chomp.to_s) ? current_plugin_ver.to_s : "Up-to-Date"
  end

  if (continue_target)
    target_ver_diff = (target_plugin_ver.to_s > p_ver.chomp.to_s) ? target_plugin_ver.to_s : "Up-to-Date"
    if (target_required_core < "2.277.2.1")
      notes = add_note(notes, "Target Version required Core pre-dates Tables-to-DIVs change. Check this plugin for compatibility!")
    end
  end

  # Output our CSV to a file
  csv << [p_id, p_ver.chomp, current_ver_diff.to_s, target_ver_diff.to_s, target_required_core, in_uc_current.to_s, in_uc_target.to_s, in_cap_current.to_s, in_cap_target.to_s, notes]
end

# Close the CSV for writing
csv.close