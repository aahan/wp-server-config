// Imports
import std; // import logging

// Defining our backends
backend myFirstServer {
  .host = "myFirstServer.mclear.co.uk";
  .port = "8080";
  .probe = {
    .url = "/index.html";
    .interval = 5s;
    .timeout = 1 s;
    .window = 5;
    .threshold = 3;
  }
  .connect_timeout = 600s;
  .first_byte_timeout = 600s;
  .between_bytes_timeout = 600s;
}
 
backend mySecondServer {
  .host = "mySecondServer.mclear.co.uk";
  .port = "8080";
  .probe = {
    .url = "/index.html";
    .interval = 5s;
    .timeout = 1 s;
    .window = 5;
    .threshold = 3;
  }
  .connect_timeout = 600s;
  .first_byte_timeout = 600s;
  .between_bytes_timeout = 600s;
}
 
// Defining our cluster including end points for purge
director cluster round-robin {
  {.backend = myFirstServer;}
  {.backend = mySecondServer;}
}
 
// End points for purge requests
acl purge {
  "myFirstServer.mclear.co.uk";
  "mySecondServer.mclear.co.uk";
}
 
sub vcl_fetch{
  // When fetching images we can set a long caching marker that we can access later
  if (req.request == "GET" && req.url ~ "\.(jpg|jpeg|gif|ico|css|js|png)$") {
    set beresp.http.magicmarker = "1";
  }
  // Don't cache mobile requests
  if (req.http.X-Device == "mobile"){
    set beresp.ttl = 0s;
    std.log("Not caching mobile requests");
  }
  // Don't cache error pages
  if (beresp.status == 404 || beresp.status == 503 || beresp.status >= 500){
    set beresp.ttl = 0s;
  }
 
  // Some debug code for why objects are/aren't cachable
  // Varnish determined the object was not cacheable
  if (!beresp.ttl > 0s) {
      set beresp.http.X-Cacheable = "NO:Not Cacheable";
 
  // You don't wish to cache content for logged in users
  } elsif (req.http.Cookie ~ "(UserID|_session)") {
      set beresp.http.X-Cacheable = "NO:Got Session";
      std.log("It appears a session is in process so we have returned pass");
      return(deliver);
 
  // You are respecting the Cache-Control=private header from the backend
  } elsif (beresp.http.Cache-Control ~ "private") {
      set beresp.http.X-Cacheable = "NO:Cache-Control=private";
      std.log("It appears this is private so we have returned pass");
      return(deliver);
 
  // You are extending the lifetime of the object artificially
  } elsif (beresp.ttl < 1s) {
      set beresp.ttl   = 5s;
      set beresp.grace = 5s;
      set beresp.http.X-Cacheable = "YES:FORCED";
   // Varnish determined the object was cacheable
  } else {
   set beresp.http.X-Cacheable = "YES";
  }
}
 
sub vcl_recv
  {
  set req.http.X-Forwarded-For = client.ip; // Set the client IP
  set req.backend = cluster; // Set the backend to the cluster
  call device_detection; // Check for a mobile device
 
  // Purge WordPress requests for purge
  if (req.request == "PURGE") {
    if (!client.ip ~ purge) {
      error 405 "Not allowed.";
    }
    ban("req.url = " + req.url + " && req.http.host = " + req.http.host);
    error 200 "Purged.";
  }
 
  // Cache static objects such as images
  if (req.request == "GET" && req.url ~ "\.(jpg|jpeg|gif|ico|css|js|png)$") {
    unset req.http.cookie;
    std.log("request is for a file such as jpg jpeg etc so dropping cookie");
    return(lookup);
  }
 
  /*
  // Cache any dynamic content
  if (req.url !~ "wp-(login|admin|signup)" && req.url !~ "preview" || req.url ~ "admin-ajax.php"){
    std.log("Request is not for login, admin, preview, sign up or admin-ajax so don't cache it");
      if (req.http.Cookie !~ "wordpress_logged_in "){
        std.log("User is not logged in");
        if (req.http.Cookie !~ "wp-postpass"){
          std.log("Post is not password protected");
          unset req.http.cookie;
          return(lookup);
        }
      }
    }
  }
  */
}
 
sub vcl_deliver {
  if (resp.http.magicmarker) {
    std.log("Magicmarker set so setting our own client side caching");
    unset resp.http.magicmarker;
    set resp.http.Cache-Control = "max-age=648000";
    set resp.http.Expires = "Thu, 01 May 2014 00:10:22 GMT";
    set resp.http.Last-Modified = "Mon, 25 Apr 2011 01:00:00 GMT";
    set resp.http.Age = "647";
  }
}
 
sub device_detection {
  // Default to thinking it's a PC
  set req.http.X-Device = "pc";
 
  // Add all possible agent strings - These are the most popular agent strings
  std.log("Checking for mobile device");
  if (req.http.User-Agent ~ "iP(hone|od)" || req.http.User-Agent ~ "Android" || req.http.User-Agent ~ "Symbian" || req.http.User-Agent ~ "^BlackBerry" || req.http.User-Agent ~ "^SonyEricsson"
    || req.http.User-Agent ~ "^Nokia" || req.http.User-Agent ~ "^SAMSUNG" || req.http.User-Agent ~ "^LG" || req.http.User-Agent ~ "webOS") {
    std.log("Mobile device detected");
    std.log("Following req.url");
    if (req.url !~ "wptouch_view=normal"){
      std.log("wptouch_switch_toggle is not set");
      set req.http.X-Device = "mobile";
    }
    else{
      std.log("this should not be redirecting to mobile");
      std.log("wp touch view is set to normal so we shouldn't be setting a device type other thna PC");
      set req.http.X-Device = "pc";
      error 750 req.http.host;
    }
  }
 
  // These are some more obscure agent strings
  if (req.http.User-Agent ~ "^PalmSource"){
    set req.http.X-Device = "mobile";
  }
}
