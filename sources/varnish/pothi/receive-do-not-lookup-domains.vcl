# Do not look for cache of all domains, except the primary domain
# Comment out only one of the following *if* conditions

# If multiple domains are used, comment out both

if (req.http.Host != "domainname.com") { return (pass); }
# if (req.http.Host != "www.domainname.com") { return (pass); }
