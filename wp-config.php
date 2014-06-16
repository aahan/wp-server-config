<?php

/*
 * Tell WordPress/PHP to get client IP address from `X-Forwarded-For` HTTP header set by Varnish
 * (First, Varnish should be configured to do so; see varnish/default.vcl)
 */
if ( isset( $_SERVER[ 'HTTP_X_FORWARDED_FOR' ] ) ) {
	$_SERVER[ 'REMOTE_ADDR' ] = $_SERVER[ 'HTTP_X_FORWARDED_FOR' ];
}


/*
 * General Configurations
 */

# Disable post revisions
# define( 'WP_POST_REVISIONS', false );

# Set autosave interval
# define( 'AUTOSAVE_INTERVAL', 160 );

# Increase PHP memory limit
# define( 'WP_MEMORY_LIMIT', '64M' );


/*
 * Define URL of 'wp-content' directory
 * (Used to serve static content via an Origin-pull CDN e.g. CloudFront, MaxCDN)
 * http://codex.wordpress.org/Editing_wp-config.php#Moving_wp-content_folder
 * http://wordpress.stackexchange.com/a/134860
 */

# For Normal Site
# define( 'WP_CONTENT_URL', 'http://cdn.example.com/wp-content' );

# For Multisite
# define( 'CURRENT_SITE_DOMAIN', $_SERVER['HTTP_HOST'] );
# if( 'site1.com' == CURRENT_SITE_DOMAIN ) {
# 	define( 'WP_CONTENT_URL', 'http://abcdefghijk.cloudfront.net/wp-content' );
# } elseif( 'site2.com' == CURRENT_SITE_DOMAIN ) {
# 	define( 'WP_CONTENT_URL', 'http://kjihgfedcba.cloudfront.net/wp-content' );
# } else {
# 	define( 'WP_CONTENT_URL', 'http://pqrstuvwxyz.cloudfront.net/wp-content' );
# }


# [...]
#
# OTHER DEFAULT WP-CONFIG.PHP CONTENTS
#
# [...]


/*
 * Multisite Configurations
 */

# 
# define( 'WP_ALLOW_MULTISITE', true );
# [Add WordPress generated Multisite Network rules here.]

# Redirect non-existent blogs to main site
# define( 'NOBLOGREDIRECT', 'http://example.com/' );

# Enable Akismet Anti-Spam Protection For Entire Network
# define( 'WPCOM_API_KEY', 'YOUR_AKISMET_KEY' );


/* That's all, stop editing! Happy blogging. */


# [...]
#
# OTHER DEFAULT WP-CONFIG.PHP CONTENTS
#
# [...]
