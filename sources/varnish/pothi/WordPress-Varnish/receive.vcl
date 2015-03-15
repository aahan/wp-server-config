if (req.restarts == 0) {
  if (req.http.x-forwarded-for) {
    set req.http.X-Forwarded-For =
      req.http.X-Forwarded-For + ", " + client.ip;
  } else {
    set req.http.X-Forwarded-For = client.ip;
  }
}

if (req.request == "PURGE") {
  if(!client.ip ~ purge) {
    error 405 "Not allowed.";
  }

  # No need to process further conditions; just purge the cache
  return(lookup);
}

if (req.request != "GET" &&
  req.request != "HEAD" &&
  req.request != "PUT" &&
  req.request != "POST" &&
  req.request != "TRACE" &&
  req.request != "OPTIONS" &&
  req.request != "DELETE") {

  /* Non-RFC2616 or CONNECT which is weird. */
  return (pipe);
}

if (req.request != "GET" && req.request != "HEAD") {
  /* We only deal with GET and HEAD by default */
  return (pass);
}

# Normalize the "Accept-Encoding" headers
if (req.http.Accept-Encoding) {
  if (req.url ~ "\.(jpg|png|gif|gz|tgz|bz2|tbz|mp3|ogg)$") {
    # No point in compressing these
    remove req.http.Accept-Encoding;
  } elsif (req.http.Accept-Encoding ~ "gzip") {
    set req.http.Accept-Encoding = "gzip";
  } elsif (req.http.Accept-Encoding ~ "deflate" && req.http.user-agent !~ "MSIE") {
    set req.http.Accept-Encoding = "deflate";
  } else {
    # unkown algorithm
    remove req.http.Accept-Encoding;
  }
}

