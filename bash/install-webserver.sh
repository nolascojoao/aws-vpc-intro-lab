#!/bin/bash
# Installs the Apache web server            
yum -y install httpd
# Configures httpd to start on boot      
systemctl enable httpd
# Starts the httpd service now    
systemctl start httpd
# Creates an HTML homepage
echo '<html><h1>Hello From Your Web Server!</h1></html>' > /var/www/html/index.html 