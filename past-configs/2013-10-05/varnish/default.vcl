backend default {
  .host = "127.0.0.1";
  .port = "8080";
}

acl purge {
  "127.0.0.1";
  "localhost";
}


# Called when a request is received
sub vcl_recv {

  # Send client IP with X-Forwarded-For HTTP header
  #
  # Sources:
  # http://systemsarchitect.net/boost-wordpress-performance-with-varnish-cache/
  # http://ocaoimh.ie/2011/08/09/speed-up-wordpress-with-apache-and-varnish/
  remove req.http.X-Forwarded-For;
  set req.http.X-Forwarded-For = client.ip;

  # Purge WordPress requests for purge
  if (req.request == "PURGE") {
    if (!client.ip ~ purge) {
      error 405 "Not allowed.";
    }
    ban("req.url ~ ^" + req.url + "$ && req.http.host == " + req.http.host);
    error 200 "Purged.";
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

  # Requests for login, admin, sign up, preview, password protected posts, admin-ajax, etc. (WordPress & bbPress)
  if (req.url ~ "(wp-login|wp-admin|wp-signup|wp-comments-post.php|wp-cron.php|admin-ajax.php|xmlrpc.php|preview=true|nocache|control.php|bb-login.php|bb-reset-password.php|register.php)" || req.http.Cookie ~ "(wp-postpass|wordpress_logged_in|comment_author_)" || req.http.X-Requested-With == "XMLHttpRequest") {
    return (pass);
  }

  remove req.http.cookie;
  return (lookup);

}


# Remove some unnecessary headers
sub vcl_deliver {
  remove resp.http.Server;
  remove resp.http.X-Powered-By;
  remove resp.http.X-Varnish;
  remove resp.http.Age;
  remove resp.http.Via;
  remove resp.http.X-W3TC-Minify;
}


# Called after a document has been successfully retrieved from the backend
sub vcl_fetch {

  if (beresp.status == 404 || beresp.status == 503 || beresp.status >= 500) {
    set beresp.ttl = 0m;
    return(hit_for_pass);
  }

  # Requests for login, admin, sign up, preview, password protected posts, admin-ajax, etc. (WordPress & bbPress)
  if (req.url ~ "(wp-login|wp-admin|wp-signup|wp-comments-post.php|wp-cron.php|admin-ajax.php|xmlrpc.php|preview=true|nocache|control.php|bb-login.php|bb-reset-password.php|register.php)" || req.http.Cookie ~ "(wp-postpass|wordpress_logged_in|comment_author_)" || req.http.X-Requested-With == "XMLHttpRequest") {
    return (hit_for_pass);
  }

  # Don't cache .xml files (e.g. sitemap)
  if (req.url ~ "\.(xml)$") {
    set beresp.ttl = 0m;
  }

  # Cache HTML
  # if (req.url ~ "\.(html|htm)$") {
  #   set beresp.ttl = 60m;
  # }

  remove beresp.http.set-cookie;
  set beresp.ttl = 24h;
  return (deliver);

}
