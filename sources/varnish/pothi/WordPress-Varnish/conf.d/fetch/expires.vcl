# use case #1 - Apache backend without mod_expires
# use case #2 - Remove the expires header that the backend sends. Ex: Nginx `expires` directive

if ( req.url ~ "\.(jpg|jpeg|png|gif|ico|tiff|tif|bmp|ppm|pgm|xcf|psd|webp|svg)"
  || req.url ~ "\.(css|js)"
  || req.url ~ "\.html?$"
  || req.url ~ "\.(woff|eot|otf|ttf)"
   ) {

  unset beresp.http.expires;
  unset beresp.http.Cache-Control;
  set beresp.http.Cache-Control = "max-age=2678400";
}
