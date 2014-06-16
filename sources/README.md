## Sources/References

**wp-config.php:**

- [Tell WordPress/PHP to get client IP address from `X-Forwarded-For` HTTP header set by Varnish](http://ocaoimh.ie/2011/08/09/speed-up-wordpress-with-apache-and-varnish/) by Donncha O Caoimh

**Apache:**

- HTML5 Boilerplate's [Server Configs](https://github.com/h5bp/server-configs)
	- H5BP [Apache Configs](https://github.com/h5bp/server-configs-apache)
- [W3 Total Cache](https://wordpress.org/plugins/w3-total-cache/): From W3 Total Cache Settings (WP-ADMIN > Performance > Install > .htaccess Rewrite rules), after installing the plugin and setting up certain features, e.g. Browser Cache, CDN, etc.

**Varnish:**

- DreamHost's [Varnish VCL Collection](https://github.com/dreamhost/varnish-vcl-collection)
- mattiasgeniar/[varnish-3.0-configuration-templates](https://github.com/mattiasgeniar/varnish-3.0-configuration-templates) & ([varnish-4.0](https://github.com/mattiasgeniar/varnish-4.0-configuration-templates))
- [W3 Total Cache](https://wordpress.org/plugins/w3-total-cache/) (see: ini/varnish-sample-config.vcl)
- Ipstenu/[varnish-http-purge](https://github.com/Ipstenu/varnish-http-purge) ([WordPress Plugin](http://wordpress.org/plugins/varnish-http-purge/))
- pothi/[WordPress-Varnish](https://github.com/pothi/WordPress-Varnish)
- pkhamre/[wp-varnish](https://github.com/pkhamre/wp-varnish)
- admingeekz/[varnish-wordpress](https://github.com/admingeekz/varnish-wordpress)
- ewanleith/[Wordpress-Server-Configuration-Files](https://github.com/ewanleith/Wordpress-Server-Configuration-Files)
- nicolargo/[varnish-nginx-wordpress](https://github.com/nicolargo/varnish-nginx-wordpress)
- JohnMcLear/[Wordpress-Varnish-VCL](https://github.com/JohnMcLear/Wordpress-Varnish-VCL)
- [Varnish WordPress VCL Example Templates](https://www.varnish-cache.org/trac/wiki/VCLExamples#VCLExampleTemplates)
- VCL Basics > [VCL Request Flow](https://www.varnish-software.com/static/book/VCL_Basics.html#vcl-request-flow)