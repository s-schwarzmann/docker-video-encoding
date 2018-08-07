# WEBDAV-based Workers

Install *davfs2*:

	sudo apt-get install davfs2

Mount the webdav folder: 

	sudo mount.davfs -o uid=`whoami` YOUR_WEBDAV_URL WEBDAV/

