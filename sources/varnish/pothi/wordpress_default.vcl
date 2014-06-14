include "backend.vcl";
include "acl.vcl";

sub vcl_recv {
  # include "conf.d/receive/pagespeed.vcl";
  include "receive.vcl";
  include "receive-do-not-lookup.vcl";
  include "receive-do-not-lookup-domains.vcl";
  include "receive-do-not-lookup-static-content.vcl";

  # https://www.varnish-cache.org/docs/3.0/tutorial/handling_misbehaving_servers.html#grace-mode
  if (! req.backend.healthy) {
     set req.grace = 5m;
  } else {
     set req.grace = 15s;
  }

  # Let Pagespeed fully optimize a request before it is cached
  set req.http.X-PSA-Blocking-Rewrite = "fullyoptimized";

  # custom rules

  return (lookup);
}

sub vcl_hit {
    if (req.request == "PURGE") {
        purge;
        error 200 "Purged";
    }
    return (deliver);
}

sub vcl_miss {
    if (req.request == "PURGE") {
        purge;
        error 200 "Purged";
    }
    return (fetch);
}

sub vcl_fetch {
  include "fetch.vcl";
  include "fetch-do-not-cache.vcl";
  # include "conf.d/fetch/pagespeed.vcl";
  include "fetch-do-not-cache-domains.vcl";
  include "fetch-do-not-cache-static-content.vcl";

  # custom rules
  # include "conf.d/fetch/expires.vcl";
  # include "conf.d/fetch/gzip.vcl";

  # Saint mode
  # https://www.varnish-cache.org/docs/3.0/tutorial/handling_misbehaving_servers.html#saint-mode
  if (beresp.status == 500) {
    set beresp.saintmode = 10s;
    # No restart, if only one server is present
    # return(restart);
  }
  set beresp.grace = 5m;

  # if a requests reaches this stage, then it is cacheable
  set beresp.http.X-Cacheable = "YES";

  # The default value of 120s can be modified here
  # set beresp.ttl = 300s;

  return (deliver);
}

sub vcl_deliver {
  # If your site uses CloudFront, you may want to enable / uncomment the following
  # include "conf.d/deliver/cloudfront.vcl;

  ### Uncomment the following, if Varnish handles compression
  # set resp.http.Vary = "Accept-Encoding";

  # Display the number of hits
  if (obj.hits > 0) {
    set resp.http.X-Cache = "HIT - " + obj.hits;
  } else {
    set resp.http.X-Cache = "MISS";
  }

  # Comment it out to see useful headers (for example, while debugging)
  # include "conf.d/deliver/hide_headers.vcl";

  return (deliver);
}

# The data on which the hashing will take place
sub vcl_hash {
    hash_data(req.url);

    if (req.http.host) {
        hash_data(req.http.host);
    } else {
        hash_data(server.ip);
    }

    # hash cookies for object with auth
    if (req.http.Cookie) {
        hash_data(req.http.Cookie);
    }
    if (req.http.Authorization) {
        hash_data(req.http.Authorization);
    }

    # If the client supports compression, keep that in a different cache
    if (req.http.Accept-Encoding) {
        hash_data(req.http.Accept-Encoding);
    }

    return (hash);
}

