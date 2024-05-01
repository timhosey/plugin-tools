#!/usr/bin/env ruby

require 'open-uri'
require 'JSON'

# This should be externalized somehow as a param
current_version = '2.346.4.1'
target_version = '2.414.1.4'

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

def check_if_cap(plugin_name, json)
  begin
    checker = json["offeredEnvelope"]["plugins"][plugin_name]["artifactId"]
    return true
  rescue => e
    return false
  end
end

def check_for_update(start_ver, target_ver, plugin_name, json)
  in_cap = check_if_cap(plugin_name, json)
  icon = in_cap ? "*" : ""
  if (target_ver > start_ver)
    return "#{icon}$ #{plugin_name} has an update available. It is highly recommended you upgrade this plugin to #{target_ver.chomp} from #{start_ver.chomp} after upgrading."
  else
    return "#{icon}% #{plugin_name} should be fine post-upgrade as #{start_ver.chomp} is currently the best version available for your environment."
  end
end

unless File.exists?("uc.json")
  http_download_uri("https://jenkins-updates.cloudbees.com/update-center.json", "uc.json")
  trimmed = system('sed', '-i', 'uc.bak', '1d;$d', 'uc.json')
  
else
  puts "Skipping download of JSON."
end 

p_json = JSON.parse(File.read('uc.json'))
File.open("active.txt", "r") do |file_handle|
  file_handle.each_line do |plugin|
    p_split = plugin.split(":")
    p_name = p_split[0]
    p_ver = p_split[1]
    #puts "NAME: #{p_name}, VER: #{p_ver}"
    begin
      p_remote_ver = p_json["plugins"][p_name]["version"]
      p_required_core = p_json["plugins"][p_name]["requiredCore"]
    rescue => e
      File.open('new_vers.txt', 'a') do |ver_file|
        ver_file.puts "& Plugin #{p_name} not found in Update Center. Skipping..."
      end
      next
    end
    if p_remote_ver.chomp != p_ver.chomp
      File.open('new_vers.txt', 'a') do |ver_file|
        if (p_required_core.chomp < "2.277.2.1")
          ver_file.puts "! #{p_name} is only supported on versions older than tables-to-divs! It is HIGHLY recommended this plugin be removed for compatibility and security concerns. [req_core] #{p_required_core}"
        elsif (p_required_core.chomp > target_version)
          ver_file.puts "@ #{p_name} requires a version greater than the target of #{target_version}. Manually validate the version needed for install. [req_core] #{p_required_core}"
        else
          ver_file.puts check_for_update(p_ver, p_remote_ver, p_name, p_json)
        end
      end
    end
  end
end