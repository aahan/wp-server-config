=== Varnish WordPress ===
Contributors: admingeekz
Tags: Varnish WordPress,  WordPress Varnish,  Varnish Cache,  WordPress Cache,  High Performance WordPress,  Cache WordPress,  Fast WordPress
Requires at least: 3.4
Tested up to: 3.9.1
Stable tag: 1.5
License: GPLv2 or later
License URI: http://www.gnu.org/licenses/gpl-2.0.html

This plugin enables you to use the Varnish cache with WordPress,  designed for high performance websites.

== Description ==

This is a plugin for wordpress to intergrate the varnish cache for high performance websites.

This plugin will purge the cache on,

*  Post changes (new, edit, trash, delete).
*  Page changes (add, edit, remove)
*  Comment changes (add, edit, approve,  unapprove,  spam,  trash,  delete)
*  Theme changes

= Features =

At present some of the features are,

*  Multiple varnish backends
*  Manually purge the cache
*  Enable/Disable Feed Purging
*  Ability to purge entire cache on changes
*  Debug logging
*  Minimize number of purges and remove duplicate purges for speed on larger installations
*  Actively maintained

= Speed =

Our tests show that by utilizing varnish you gain a ~70x capacity increase over standard WordPress making you resistant to traffic floods (slashdot,  digg, reddit,  stumbleupon).

== Installation == 

= To install the WordPress plugin. =

1. Get the latest version from https://www.admingeekz.com/files/varnish-wordpress.zip
2. Copy the varnish-wordpress folder to wp-content/plugins/
3. Login to wp-admin
4. Go to Plugins->Installed Plugins on the left menu
5. Under "Varnish WordPress" click "Activate"
6. You should now see the varnish menu under "Settings"

= To install the varnish VCL. =

1. Copy the file "default.vcl" provided with this plugin  to your varnish installation path (/etc/varnish/default.vcl on most systems)
2. Configure the backend in the default.vcl to point to the ip and port your webserver(s) are running on
3. Restart varnish

= To configure the WordPress plugin =

1. In the varnish backends box input the backends we need to access to purge the cache. (Format:  ip:port)
2. Check the enabled box
3. Click Save

The setup should be complete.   You can enable Debug Logging temporarily to monitor what the plugin is doing.   Test by enabling debug logging and adding a new post.


== Frequently Asked Questions ==

= I have a question =

Check the latest FAQ at the plugin home page on our website at <a href="http://www.admingeekz.com/varnish-wordpress">Varnish WordPress</a>

== Screenshots ==

1. Screenshot of the performance tests.
2. Screenshot of the WordPress plugin.

== Changelog ==

= 1.5 =
* Introduce support for separate wp-admin backend to allow for longer timeouts
* Add comments/support to default varnish config for multiple domains/subdomains and SSL
* Bugfix: the timeout for backends was not processed so defaulted to 0 seconds
* Bugfix: typo in the error reporting when unable to connect to a backend
* Bugfix: default styling for checkboxes was malformed in certain themes

= 1.4 =
* Updating readme, screenshots and installation documents to package and list as a plugin in the WordPress directory

= 1.3 =
* Processing purges on shutdown to prevent duplicates
* Reintroduced transition status hook
* Purge on theme change 
* Moved to github

= 1.2 =
* Added disable feed purge option
* Added purge all option
* Added manual purge option
* Fixed a bug where the cache would not clear if you had wordpress in a subdirectory
* Minor text and formatting bug fixes

= 1.1 =
* Added debug logging option
* Added timeout option for varnish connections
* Removed transition status hook,  causes duplicate purges.

= 1.0 =
* Initial release

== Upgrade Notice ==

= 1.4 =
Now available via the WordPress plugin directory

= 1.3 =
This release contains several performance enhancements and extra purge support.
