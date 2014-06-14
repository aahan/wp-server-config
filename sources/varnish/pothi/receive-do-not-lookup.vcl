# Pipe possibly large-sized objects; except sitemaps
if (req.url ~ "^[^?]*\.(zip|tar|gz|tgz|bz2|mp[34]|pdf|rar|rtf|swf|wav)(\?.*)?$") {
  if (req.url ~ "sitemap") { }
  else {
    return (pipe);
  }
}

# Check the cookies for wordpress-specific cookies
if (req.http.Cookie ~ "wordpress_" || req.http.Cookie ~ "comment_") {
  return (pass);
}

# Check the admin pages
if (req.url ~ "wp-(login|admin/)" || req.url ~ "preview=true") {
  return (pass);
}

# Contact Pages
if (req.url ~ "contact") {
  return (pass);
}
