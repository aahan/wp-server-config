### This file basically contains things that shouldn't be cached by Varnish after fetching from the backend

# Admin pages
if (req.url ~ "wp-(login|admin/)" || req.url ~ "preview=true") {
  set beresp.http.X-Cacheable = "NO: User is logged-in!";
  set beresp.http.Cache-Control = "max-age=0";
  return (hit_for_pass);
}

# PHP
if (req.url ~ "\.php$") {
  set beresp.http.X-Cacheable = "NO: PHP!";
  return (hit_for_pass);
}

# Contact Pages
if (req.url ~ "contact") {
  set beresp.http.X-Cacheable = "NO: Contact Page";
  return (hit_for_pass);
}


# If backend response is NOT 200.
if (beresp.status != 200) {
  set beresp.http.Cache-Control = "max-age=0";
  set beresp.http.X-Cacheable = "NO: Backup HTTP response is not 200";
  return (hit_for_pass);
}


