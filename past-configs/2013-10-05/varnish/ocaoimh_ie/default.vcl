# SOURCE: http://ocaoimh.ie/2011/08/09/speed-up-wordpress-with-apache-and-varnish/

# Called after a document has been successfully retrieved from the backend.
sub vcl_fetch {
    # Uncomment to make the default cache "time to live" is 5 minutes, handy 
    # but it may cache stale pages unless purged. (TODO)
    # By default Varnish will use the headers sent to it by Apache (the backend server)
    # to figure out the correct TTL. 
    # WP Super Cache sends a TTL of 3 seconds, set in wp-content/cache/.htaccess
 
    # set beresp.ttl   = 300s;
 
    # Strip cookies for static files and set a long cache expiry time.
    if (req.url ~ "\.(jpg|jpeg|gif|png|ico|css|zip|tgz|gz|rar|bz2|pdf|txt|tar|wav|bmp|rtf|js|flv|swf|html|htm)$") {
            unset beresp.http.set-cookie;
            set beresp.ttl   = 24h;
    }
 
    # If WordPress cookies found then page is not cacheable
    if (req.http.Cookie ~"(wp-postpass|wordpress_logged_in|comment_author_)") {
        set beresp.cacheable = false;
    } else {
        set beresp.cacheable = true;
    }
 
    # Varnish determined the object was not cacheable
    if (!beresp.cacheable) {
        set beresp.http.X-Cacheable = "NO:Not Cacheable";
    } else if ( req.http.Cookie ~"(wp-postpass|wordpress_logged_in|comment_author_)" ) {
        # You don't wish to cache content for logged in users
        set beresp.http.X-Cacheable = "NO:Got Session";
        return(pass);
    }  else if ( beresp.http.Cache-Control ~ "private") {
        # You are respecting the Cache-Control=private header from the backend
        set beresp.http.X-Cacheable = "NO:Cache-Control=private";
        return(pass);
    } else if ( beresp.ttl < 1s ) {
        # You are extending the lifetime of the object artificially
        set beresp.ttl   = 300s;
        set beresp.grace = 300s;
        set beresp.http.X-Cacheable = "YES:Forced";
    } else {
        # Varnish determined the object was cacheable
        set beresp.http.X-Cacheable = "YES";
    }
    if (beresp.status == 404 || beresp.status >= 500) {
        set beresp.ttl = 0s;
    }
 
    # Deliver the content
    return(deliver);
}
 
sub vcl_hash {
    # Each cached page has to be identified by a key that unlocks it.
    # Add the browser cookie only if a WordPress cookie found.
    if ( req.http.Cookie ~"(wp-postpass|wordpress_logged_in|comment_author_)" ) {
        set req.hash += req.http.Cookie;
    }
}
 
# Deliver
sub vcl_deliver {
    # Uncomment these lines to remove these headers once you've finished setting up Varnish.
    #remove resp.http.X-Varnish;
    #remove resp.http.Via;
    #remove resp.http.Age;
    #remove resp.http.X-Powered-By;
}
 
# vcl_recv is called whenever a request is received
sub vcl_recv {
    # remove ?ver=xxxxx strings from urls so css and js files are cached.
    # Watch out when upgrading WordPress, need to restart Varnish or flush cache.
    set req.url = regsub(req.url, "\?ver=.*$", "");
 
    # Remove "replytocom" from requests to make caching better.
    set req.url = regsub(req.url, "\?replytocom=.*$", "");
 
    remove req.http.X-Forwarded-For;
    set    req.http.X-Forwarded-For = client.ip;
 
    # Exclude this site because it breaks if cached
    #if ( req.http.host == "example.com" ) {
    #    return( pass );
    #}
 
    # Serve objects up to 2 minutes past their expiry if the backend is slow to respond.
    set req.grace = 120s;
    # Strip cookies for static files:
    if (req.url ~ "\.(jpg|jpeg|gif|png|ico|css|zip|tgz|gz|rar|bz2|pdf|txt|tar|wav|bmp|rtf|js|flv|swf|html|htm)$") {
        unset req.http.Cookie;
        return(lookup);
    }
    # Remove has_js and Google Analytics __* cookies.
    set req.http.Cookie = regsuball(req.http.Cookie, "(^|;\s*)(__[a-z]+|has_js)=[^;]*", "");
    # Remove a ";" prefix, if present.
    set req.http.Cookie = regsub(req.http.Cookie, "^;\s*", "");
    # Remove empty cookies.
    if (req.http.Cookie ~ "^\s*$") {
        unset req.http.Cookie;
    }
    if (req.request == "PURGE") {
        if (!client.ip ~ purge) {
                error 405 "Not allowed.";
        }
        purge("req.url ~ " req.url " && req.http.host == " req.http.host);
        error 200 "Purged.";
    }
 
    # Pass anything other than GET and HEAD directly.
    if (req.request != "GET" && req.request != "HEAD") {
        return( pass );
    }      /* We only deal with GET and HEAD by default */
 
    # remove cookies for comments cookie to make caching better.
    set req.http.cookie = regsub(req.http.cookie, "1231111111111111122222222333333=[^;]+(; )?", "");
 
    # never cache the admin pages, or the server-status page
    if (req.request == "GET" && (req.url ~ "(wp-admin|bb-admin|server-status)")) {
        return(pipe);
    }
    # don't cache authenticated sessions
    if (req.http.Cookie && req.http.Cookie ~ "(wordpress_|PHPSESSID)") {
        return(pass);
    }
    # don't cache ajax requests
    if(req.http.X-Requested-With == "XMLHttpRequest" || req.url ~ "nocache" || req.url ~ "(control.php|wp-comments-post.php|wp-login.php|bb-login.php|bb-reset-password.php|register.php)") {
        return (pass);
    }
    return( lookup );
}
