#!/usr/bin/env ruby

require 'open-uri'
require 'JSON'

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
    p_remote_ver = p_json["plugins"][p_name]["version"]
    p_required_core = p_json["plugins"][p_name]["requiredCore"]
    if p_remote_ver.chomp != p_ver.chomp
      File.open('new_vers.txt', 'a') do |ver_file|
        if (p_required_core.chomp < "2.277.2.1")
          ver_file.puts "!*** #{p_name} is only supported on versions older than tables-to-divs! [req_core] #{p_required_core}"
        else
          ver_file.puts "#{p_name} version mismatch.\n [inst] #{p_ver.chomp} [remote] #{p_remote_ver.chomp}"
        end
      end
    end
  end
end