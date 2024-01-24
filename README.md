# CBCI and Jenkins Plugin Scripts
This is a repo of various plugin-related scripts I've written or used to help customers.

## check_plugins.rb
This script, likely to be renamed down the road (TODO), takes a list of plugins (formatted as plugin_name:version) as a text file and downloads and compares to the CBCI UC JSON, returning plugins that haven't been updated since the table-to-div switch and also identifying not-updated plugins. This could probably be easily tweaked to do a lot more with the JSON data there. Returns results as a text file.