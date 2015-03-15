# To work around the IE6 (and only early versions of IE6 had it) bug with gzip
if (req.http.user-agent ~ “MSIE 6”) {
  unset req.http.accept-encoding;
}
