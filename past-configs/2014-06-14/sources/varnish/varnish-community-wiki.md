# Source: https://www.varnish-cache.org/trac/wiki/VCLExampleHitMissHeader

# To add a header indicating whether a request was a cache-hit or miss, check
# `obj.hits` in `vcl_deliver`:
sub vcl_deliver {
	if (obj.hits > 0) {
		set resp.http.X-Cache = "HIT";
	} else {
		set resp.http.X-Cache = "MISS";
	}
}

# Adding diagnostics on why there was a hit/miss
sub vcl_fetch {

	# Varnish determined the object was not cacheable
	if (beresp.ttl <= 0s) {
		set beresp.http.X-Cacheable = "NO:Not Cacheable";

	# You don't wish to cache content for logged in users
	} elsif (req.http.Cookie ~ "(UserID|_session)") {
		set beresp.http.X-Cacheable = "NO:Got Session";
		return(hit_for_pass);

	# You are respecting the Cache-Control=private header from the backend
	} elsif (beresp.http.Cache-Control ~ "private") {
		set beresp.http.X-Cacheable = "NO:Cache-Control=private";
		return(hit_for_pass);

	# Varnish determined the object was cacheable
	} else {
		set beresp.http.X-Cacheable = "YES";
	}

	return(deliver);

}