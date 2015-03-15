# Note #1 - Make sure, you have conf.d/receive/pagespeed.vcl in vcl_receive
if (req.url ~ "\.pagespeed\.[a-z]{2}\.[^.]{10}\.[^.]+") {
  set beresp.http.X-Cacheable = "No: Pagespeed";
  return (hit_for_pass);
}

# Tell mod_pagespeed to fully optimize a page, before sending to Varnish
set req.http.X-PSA-Blocking-Rewrite = "fullyoptimized";
