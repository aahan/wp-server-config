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


acl purge {
	# Web server which will issue PURGE requests
	"localhost";
	"127.0.0.1";
}


sub vcl_recv {
	remove req.http.X-Forwarded-For;
	set req.http.X-Forwarded-For = client.ip;

	if (req.request == "PURGE" || req.request == "BAN") {
		if (!client.ip ~ purge) {
			error 405 "Not allowed.";
		}
		ban("req.url ~ ^"+req.url+"$ && req.http.host == "+req.http.host);
		error 200 "Banned.";
	}

	# Remove cookies from the request (by client) for static files
	# https://www.varnish-cache.org/lists/pipermail/varnish-misc/2011-February/019972.html
	if (req.url ~ "^/[^?]+\.(gif|jpg|jpeg|swf|css|js|txt|flv|mp3|mp4|pdf|ico|png|gz|zip|lzma|bz2|tgz|tbz)(\?.*|)$") {
		remove req.http.cookie;
	}

	# Handling CONNECT and Non-RFC2616 HTTP Methods
	# i.e. request method isn't one of the *normal* web site or web service methods
	# http://www.harecoded.com/determining-the-real-client-ip-with-varnish-w-x-forwarded-for-2177289
	# https://www.varnish-cache.org/trac/wiki/Introduction
	if (req.request != "GET"
		&& req.request != "HEAD"
		&& req.request != "PUT"
		&& req.request != "POST"
		&& req.request != "TRACE"
		&& req.request != "OPTIONS"
		&& req.request != "DELETE")
	{
		return (pipe);
	}

	if (req.request != "GET" && req.request != "HEAD") {
		return (pass);
	}

	# Don't cache when authorization header is being provided by client
	# https://www.varnish-cache.org/trac/wiki/Introduction
	# http://blog.tenya.me/blog/2011/12/14/varnish-http-authentication/
	if (req.http.Authorization || req.http.Authenticate) {
		return (pass);
	}

	# Don't cache backend
	if (req.url ~ "wp-(login|admin|comments-post.php|cron.php)" || req.url ~ "preview=true" || req.url ~ "xmlrpc.php") {
		return (pass);
	}

	return (lookup);
}


sub vcl_pipe {
	# Force every pipe request to be the first one.
	# https://www.varnish-cache.org/trac/wiki/VCLExamplePipe
	set bereq.http.connection = "close";
}


# DIAGNOSTIC HEADERS
# https://www.varnish-cache.org/trac/wiki/VCLExampleHitMissHeader
sub vcl_hit {
	if (req.request == "PURGE") {
		purge;
		error 200 "Purged.";
	}
}
sub vcl_miss {
	if (req.request == "PURGE") {
		purge;
		error 200 "Purged.";
	}
}


sub vcl_fetch {

	# BEGIN DIAGNOSTIC HEADERS
	# https://www.varnish-cache.org/trac/wiki/VCLExampleHitMissHeader

	# Uncached content for logged-in users
	if (req.http.Cookie ~ "(UserID|_session)") {
		set beresp.http.X-Cacheable = "NO:Got Session";
	}

	# Not caching backend
	elsif (req.url ~ "wp-(login|admin|comments-post.php|cron.php)" || req.url ~ "preview=true" || req.url ~ "xmlrpc.php") {
		set beresp.http.X-Cacheable = "NO:Backend";
	}

	# Uncached content
	elsif (!beresp.ttl > 0s) {
		set beresp.http.X-Cacheable = "NO:Not Cacheable";
	}

	# Cached content
	else {
		set beresp.http.X-Cacheable = "YES";
	}
	# END DIAGNOSTIC HEADERS


	# Don't cache for logged in users
	if (req.http.Cookie ~ "(UserID|_session)") {
		return(hit_for_pass);
	}

	# Don't cache backend
	# http://stackoverflow.com/a/12703836
	if (req.url ~ "wp-(login|admin|comments-post.php|cron.php)" || req.url ~ "preview=true" || req.url ~ "xmlrpc.php") {
		return (hit_for_pass);
	}

	# Don't cache error pages
	# if (beresp.status == 404 || beresp.status == 503 || beresp.status >= 500) {
	# 	return(hit_for_pass);
	# }
	#
	# But we want to cache error pages; so make sure proper error headers are sent.

	set beresp.ttl = 4h;
	return (deliver);

}

# DIAGNOSTIC HEADERS
sub vcl_deliver {
	if (obj.hits > 0) {
		set resp.http.X-Cache = "HIT";
	} else {
		set resp.http.X-Cache = "MISS";
	}
}
