# when backend doesn't have deflate or gzip, include this vcl on top of vcl_fetch
# make sure to include conf.d/receive/gzip.vcl in vcl_receive

if (beresp.http.content-type ~ "(text|application)")
  set beresp.do_gzip = true;
}

# alternative solution
# if (beresp.http.content-type ~ "text" || req.url ~ "\.(css|js|html)" ) {
  # set beresp.do_gzip = true;
# }
