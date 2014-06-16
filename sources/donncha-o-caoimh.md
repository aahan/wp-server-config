## WP-CONFIG: Donncha O Caoimh's Tip

([Source](http://ocaoimh.ie/2011/08/09/speed-up-wordpress-with-apache-and-varnish/))

Since all requests to Apache come from the local server PHP will think that the remote host is the local server. For example, comments posted to your blog will show your own server's IP address instead of the posters'.

To fix this you need to tell WordPress/PHP to get client IP address from `X-Forwarded-For` HTTP header set by Varnish, by adding this in your wp-config.php file:

```php
<?php

if ( isset( $_SERVER[ "HTTP_X_FORWARDED_FOR" ] ) ) {
	$_SERVER[ 'REMOTE_ADDR' ] = $_SERVER[ "HTTP_X_FORWARDED_FOR" ];
}
```

***NOTE:** Varnish has to set the proper `HTTP_X_FORWARDED_FOR` header for this to work. We have the necessary policies for this in our Varnish configuration file (default.vcl).*