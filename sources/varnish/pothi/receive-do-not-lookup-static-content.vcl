# Sitemaps
# Uncomment the following if statement, if WordPress SEO by Yoast is NOT used
# Because WP SEO generates the sitemaps on the fly; so that should be cached
# if (req.url ~ "\.xml(\.gz)?$") {
#   return (pass);
# }


# Images
if (req.url ~ "\.(jpg|jpeg|png|gif|ico|tiff|tif|bmp|ppm|pgm|xcf|psd|webp|svg)") {
  return (pass);
}


# CSS & JS
if (req.url ~ "\.(css|js)") {
  return (pass);
}


# HTML & text
if (req.url ~ "\.(html?|txt)") {
  return( pass );
}


# Fonts
if (req.url ~ "\.(woff|eot|otf|ttf)") {
  return (pass);
}


# Other static content
if (req.url ~ "\.(zip|sql|tar|gz|bzip2)") {
  return (pass);
}
