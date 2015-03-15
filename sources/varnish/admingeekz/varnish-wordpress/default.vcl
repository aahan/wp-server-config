# Varnish configuration for wordpress
# AdminGeekZ Ltd <sales@admingeekz.com>
# URL: www.admingeekz.com/varnish-wordpress
# Version: 1.5

#Configure the backend webserver
backend default {
  .host = "127.0.0.1";
  .port = "80";
}

# Have separate backend for wp-admin for longer timesouts
backend wpadmin {
  .host = "127.0.0.1";
  .port = "81";
  .first_byte_timeout = 500000s;
  .between_bytes_timeout = 500000s;
}


#Which hosts are allowed to PURGE the cache
acl purge {
  "127.0.0.1";
}


sub vcl_recv {
  if (req.request == "BAN") {
    if(!client.ip ~ purge) {
      error 405 "Not allowed.";
    }
    ban("req.url ~ "+req.url+" && req.http.host == "+req.http.host);
    error 200 "Banned.";
  }

  if (req.request != "GET" &&
      req.request != "HEAD" &&
      req.request != "PUT" &&
      req.request != "POST" &&
      req.request != "TRACE" &&
      req.request != "OPTIONS" &&
      req.request != "DELETE") {
    return (pipe);
  }

  if (req.request != "GET" && req.request != "HEAD") {
    return (pass);
  }

  #Don't cache admin or login pages
  if (req.url ~ "wp-(login|admin)" || req.url ~ "preview=true") {
    return (pass);
  }

  #Don't cache logged in users
  if (req.http.Cookie && req.http.Cookie ~ "(wordpress_|wordpress_logged_in|comment_author_)") {
    return(pass);
  }

  #Don't cache ajax requests, urls with ?nocache or comments/login/regiser
  if(req.http.X-Requested-With == "XMLHttpRequest" || req.url ~ "nocache" || req.url ~ "(control.php|wp-comments-post.php|wp-login.php|register.php)") {
    return (pass);
  }

  #Set backend to wpadmin backend for longer timeouts
  if (req.url ~ "/wp-admin") {
     set req.backend = wpadmin;
  }

  #Serve stale cache objects for up to 2 minutes if the backend is down
  set req.grace = 120s;

  #Remove all cookies if none of the above match
  remove req.http.cookie;

  return (lookup);
}

sub vcl_fetch {
  #Don't cache error pages
  if (beresp.status >= 400) {
    set beresp.ttl = 0m;
    return(deliver);
  }

  if (req.url ~ "wp-(login|admin)" || req.url ~ "preview=true") {
    return (hit_for_pass);
  }

  if (req.http.Cookie ~"(wp-postpass|wordpress_logged_in|comment_author_)") {
    return (hit_for_pass);
  }

  #Set the default cache time of 12 hours
  set beresp.ttl = 12h;
  return (deliver);
}

sub vcl_hash {
  
  #Uncomment if you use multiple domains/subdomains and want to maintain separate caches
  #hash_data(req.http.host);
  #Uncomment if you use SSL and want to maintain separate caches
  #hash_data(req.http.X-Forwarded-Port);

  #Set the hash to include the cookie if it exists, to maintain per user cache
  if ( req.http.Cookie ~"(wp-postpass|wordpress_logged_in|comment_author_)" ) {
    hash_data(req.http.Cookie);
  }
}


#Comment this out if you don't want to see weather there was a HIT or MISS in the headers
sub vcl_deliver {
        if (obj.hits > 0) {
                set resp.http.X-Cache = "HIT";
        } else {
                set resp.http.X-Cache = "MISS";
        }
}

