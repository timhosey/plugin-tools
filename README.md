# CBCI and Jenkins Plugin Scripts
This is a repo of various plugin-related scripts I've written or used to help customers.

## check_plugins.rb
This script, likely to be renamed down the road (TODO), takes a list of plugins (formatted as plugin_name:version) as a text file and downloads and compares to the CBCI UC JSON, returning plugins that haven't been updated since the table-to-div switch and also identifying not-updated plugins. This could probably be easily tweaked to do a lot more with the JSON data there. Returns results as a text file.

### Icon Legend
* `$ = Ready for upgrade after core update`
* `% = No update necessary based on target version`
* `& = Not found in UC`
* `! = Older than tables-to-divs change - this should be probably be removed! Do some research to check if it is impacted by this major breaking change to Jenkins core`
* `@ = The latest version of this plugin requires a newer core than you're targeting, so do manual work to figure out the version to target`
* `* = This plugin is part of the CloudBees Assurance Plugin and should auto-update assuming Beekeeper is installed and active`

### TODO
* Add option for CSV output
* CAP comparison - did a plugin move to or from CAP between versions?