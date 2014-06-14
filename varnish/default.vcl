# Read:
# https://www.varnish-cache.org/docs/3.0/tutorial/vcl.html
	# https://www.varnish-cache.org/docs/4.0/users-guide/vcl.html
# https://www.varnish-software.com/static/book/VCL_Basics.html

# TO DOs
# Varnish Tuner: https://www.varnish-software.com/blog/introducing-varnish-tuner

backend default {
	.host = "127.0.0.1";
	.port = "8080";
}

import std;

include "inc/xforward.vcl";
include "inc/purge.vcl";
include "inc/bigfiles.vcl";        # Varnish 3.0.3+
include "inc/static.vcl";

acl purge {
	"localhost";
	"127.0.0.1";
}

### WordPress-specific config ###
sub vcl_recv {
	# Handling CONNECT and Non-RFC2616 HTTP Methods
	# i.e. request method isn't one of the 'normal' web site or web service methods
	if (req.request !~ "^GET|HEAD|PUT|POST|TRACE|OPTIONS|DELETE$") {
		return(pipe);
	}

	### Check for reasons to bypass the cache!
	# never cache anything except GET/HEAD
	if (req.request != "GET" && req.request != "HEAD") {
		return(pass);
	}
	# Don't cache when authorization header is being provided by client
	if (req.http.Authorization || req.http.Authenticate) {
		return(pass);
	}
	# don't cache logged-in users or authors
	if (req.http.Cookie ~ "wp-postpass_|wordpress_logged_in_|comment_author|PHPSESSID") {
		return(pass);
	}
	# don't cache ajax requests
	if (req.http.X-Requested-With == "XMLHttpRequest") {
		return(pass);
	}
	# don't cache these special pages, e.g. urls with ?nocache or comments, login, regiser, signup, ajax, etc.
	if (req.url ~ "nocache|wp-admin|wp-(comments-post|login|signup|activate|mail|cron)\.php|preview\=true|admin-ajax\.php|xmlrpc\.php|bb-admin|server-status|control\.php|bb-login\.php|bb-reset-password\.php|register\.php") {
		return(pass);
	}

	### looks like we might actually cache it!
	# fix up the request
	set req.grace = 2m;
	set req.url = regsub(req.url, "\?replytocom=.*$", "");

	# Remove has_js, Google Analytics __*, and wooTracker cookies.
	set req.http.Cookie = regsuball(req.http.Cookie, "(^|;\s*)(__[a-z]+|has_js|wooTracker)=[^;]*", "");
	set req.http.Cookie = regsub(req.http.Cookie, "^;\s*", "");
	if (req.http.Cookie ~ "^\s*$") {
		unset req.http.Cookie;
	}

	return(lookup);
}

sub vcl_pipe {
	# Force every pipe request to be the first one.
	# https://www.varnish-cache.org/trac/wiki/VCLExamplePipe
	set bereq.http.connection = "close";
}

sub vcl_hash {
	# Add the browser cookie only if a WordPress cookie found.
	if (req.http.Cookie ~ "wp-postpass_|wordpress_logged_in_|comment_author|PHPSESSID") {
		hash_data(req.http.Cookie);
	}
}

sub vcl_fetch {
	# make sure grace is at least 2 minutes
	if (beresp.grace < 2m) {
		set beresp.grace = 2m;
	}

	# catch obvious reasons we can't cache
	if (beresp.http.Set-Cookie) {
		set beresp.ttl = 0s;
	}

	# Varnish determined the object was not cacheable
	if (beresp.ttl <= 0s) {
		set beresp.http.X-Cacheable = "NO:Not Cacheable";
		return(hit_for_pass);

	# You don't wish to cache content for logged in users
	} else if (req.http.Cookie ~ "wp-postpass_|wordpress_logged_in_|comment_author|PHPSESSID") {
		set beresp.http.X-Cacheable = "NO:Got Session";
		return(hit_for_pass);

	# You are respecting the Cache-Control=private header from the backend
	} else if (beresp.http.Cache-Control ~ "private") {
		set beresp.http.X-Cacheable = "NO:Cache-Control=private";
		return(hit_for_pass);

	# You are extending the lifetime of the object artificially
	} else if (beresp.ttl < 300s) {
		set beresp.ttl   = 300s;
		set beresp.grace = 300s;
		set beresp.http.X-Cacheable = "YES:Forced";

	# Varnish determined the object was cacheable
	} else {
		set beresp.http.X-Cacheable = "YES";
	}

	# Avoid caching error responses
	if (beresp.status == 404 || beresp.status >= 500) {
		set beresp.ttl   = 0s;
		set beresp.grace = 15s;
	}

	# Deliver the content
	return(deliver);
}

sub vcl_deliver {

	# remove resp.http.Server;
	# remove resp.http.X-Powered-By;
	# remove resp.http.X-Varnish;
	# remove resp.http.Age;
	# remove resp.http.Via;
	# remove resp.http.X-W3TC-Minify;

	# DIAGNOSTIC HEADERS
	if (obj.hits > 0) {
		set resp.http.X-Cache = "HIT";
	} else {
		set resp.http.X-Cache = "MISS";
	}

}
