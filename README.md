# README

## Directory Structure

- /sources: Source and reference files and repositories
- /past-configs: Old and (probably) out-dated configurations I've used
- Other directories hold the configurations I am currently using, and they are:
	- /apache
	- /varnish

## WordPress Server Setup

- [DigitalOcean](https://www.digitalocean.com/?refcode=b18def068b9f) for hosting (2GB VPS)
- [Ubuntu Server](http://www.ubuntu.com/server) OS
- [Apache](http://httpd.apache.org/) web server
- [Postfix](http://www.postfix.org/) with [Mandrill](http://mandrill.com/) (free) for out-going email
- [PHP](http://www.php.net/) (& necessary libraries) and [MySQL](http://dev.mysql.com/)
- [Varnish](https://www.varnish-cache.org/) and [APC](http://php.net/manual/en/book.apc.php) for caching
- [W3 Total Cache](https://wordpress.org/plugins/w3-total-cache/) for managing page and database caching