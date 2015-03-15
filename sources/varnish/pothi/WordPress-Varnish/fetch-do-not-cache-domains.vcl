# Comment out only one of the following *if* conditions
# Second *if* condition is already commented out, if you forgot to read this line;

# If you want to host multiple domains, then comment out both lines and start from scratch

if (req.http.Host != "domainname.com") { return (hit_for_pass); }
# if (req.http.Host != "www.domainname.com") { return (hit_for_pass); }
