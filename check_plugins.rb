#!/usr/bin/env ruby

require 'open-uri'
require 'JSON'
require 'csv'

# This should be externalized somehow as a param
current_version = '2.346.4.1'
target_version = '2.414.1.4'

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

 # Get if there's an update that we can install either post- or pre-upgrade
def check_for_update(start_ver, target_ver, plugin_name, json)
  in_cap = check_if_cap(plugin_name, json)
  icon = in_cap ? "*" : ""
  if (target_ver > start_ver)
    return "#{icon}$ #{plugin_name} has an update available. It is highly recommended you upgrade this plugin to #{target_ver.chomp} from #{start_ver.chomp} after upgrading."
  else
    return "#{icon}% #{plugin_name} should be fine post-upgrade as #{start_ver.chomp} is currently the best version available for your environment."
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

# Download the target version JSON
download_json(target_version)
# Download the JSON for the current version
download_json(current_version)

target_json = JSON.parse(File.read("uc-#{target_version}.json"))
File.open("active.txt", "r") do |file_handle|
  file_handle.each_line do |plugin|
    p_split = plugin.split(":")
    p_name = p_split[0]
    p_ver = p_split[1]
    #puts "NAME: #{p_name}, VER: #{p_ver}"
    begin
      target_remote_ver = target_json["plugins"][p_name]["version"]
      target_required_core = target_json["plugins"][p_name]["requiredCore"]
    rescue => e
      File.open('new_vers.txt', 'a') do |ver_file|
        ver_file.puts "& Plugin #{p_name} not found in Update Center. Skipping..."
      end
      next
    end
    if target_remote_ver.chomp != p_ver.chomp
      File.open('new_vers.txt', 'a') do |ver_file|
        if (target_required_core.chomp < "2.277.2.1")
          ver_file.puts "! #{p_name} is only supported on versions older than tables-to-divs! It is HIGHLY recommended this plugin be removed for compatibility and security concerns. [req_core] #{target_required_core}"
        elsif (target_required_core.chomp > target_version)
          ver_file.puts "@ #{p_name} requires a version greater than the target of #{target_version}. Manually validate the version needed for install. [req_core] #{target_required_core}"
        else
          ver_file.puts check_for_update(p_ver, target_remote_ver, p_name, p_json)
        end
      end
    end
  end
end

#films_info is an array of arrays

CSV.open("new_films.csv", "w") do |csv|
  csv << headers
  films_info.each do |movie|
    csv << movie
  end
end