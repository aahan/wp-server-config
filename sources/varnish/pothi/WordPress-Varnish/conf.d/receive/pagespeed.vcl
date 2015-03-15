# Note #1 - This should come at the top of vcl_recl. Better yet, put it in custom.backend.vcl
# Note #2 - Make sure, you have conf.d/fetch/pagespeed.vcl in vcl_fetch
if (req.url ~ "\.pagespeed\.[a-z]{2}\.[^.]{10}\.[^.]+") {
  set req.backend = apache;
  return (pass);
}
