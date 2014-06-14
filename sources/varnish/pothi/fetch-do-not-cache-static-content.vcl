### Include this file in your vcl_fetch, if you are going to use CDN for the following filetypes
### Remove the file types that you don't put in CDN
### Even if you don't use a CDN and if you use memory for Varnish caching, then put it in your vcl_fetch too!

# Sitemaps
# Uncomment the following if statement, if WordPress SEO by Yoast is NOT used
# Because WP SEO generates the sitemaps on the fly; so that should be cached
# if (req.url ~ "\.xml(\.gz)?$") {
#   unset beresp.http.cookie;
#   set beresp.http.X-Cacheable = "NO: Sitemaps aren't cached";
#   return (hit_for_pass);
# }


# Images
if (req.url ~ "\.(jpg|jpeg|png|gif|ico|tiff|tif|bmp|ppm|pgm|xcf|psd|webp|svg)") {
  unset beresp.http.cookie;
  set beresp.http.X-Cacheable = "NO: Images aren't cached";
  return (hit_for_pass);
}


# CSS & JS
if (req.url ~ "\.(css|js)") {
  unset beresp.http.cookie;
  set beresp.http.X-Cacheable = "NO: CSS & JS files aren't cached";
  return (hit_for_pass);
}

# HTML & Text files
if (req.url ~ "\.(html?|txt)") {
  unset beresp.http.cookie;
  set beresp.http.X-Cacheable = "NO: HTML & text files aren't cached";
  return (hit_for_pass);
}


# Fonts
if (req.url ~ "\.(woff|eot|otf|ttf)") {
  unset beresp.http.cookie;
  set beresp.http.X-Cacheable = "NO: Webfonts aren't cached";
  return (hit_for_pass);
}


# Other static content
if (req.url ~ "\.(zip|sql|tar|gz|bzip2|mp3|mp4|flv|ogg|swf)") {
  unset beresp.http.cookie;
  set beresp.http.X-Cacheable = "NO: Misc files aren't cached";
  return (hit_for_pass);
}

