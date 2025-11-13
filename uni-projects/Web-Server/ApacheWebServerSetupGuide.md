# Apache Web Server Setup on Cloud VM (with HTTPS) Step-By-Step Guide
This guide walks through setting up a seb server on a cloud-based Linux VM using Apache2, securing it with Let's Encrypt, and handling common permission issues. This set up is perfect for short-term projects or deployments. The knowledge for setting up a basic web server came from Week07 of COIT13146 "Deploy a Web Server".

## 1. Update System
First, update all system packages to ensure the server is current:
```
sudo apt update
sudo apt upgrade
```
This reduces the chance of compatibility issues of package bugs during install.

## 2. Install Apache2 Web Server
Install the Apache HTTP server:
```
sudo apt install apache2
```
Once installed, Apache starts automatically and sets up a default site accessible at the server's public IP. In this example, the public IP is: 209.38.88.129.

# Configure the Firewall
Allow HTTP and HTTPS traffic:
```
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable
```
This allows ports 80 (HTTP) and 443 (HTTPS) if using UFW (Uncomplicated Firewall).

## 4. Verify Apache is Running
Check the server's public IP address in a browser:
```
http://209.38.88.129
```
You should be greeted with Apache's default "It works!" page. 

# 5. Create Website Directory
This was originally created as a simple test directory before a domain name was obtained, hence the ".test". I just entered the domain name in the directory and continued with the same directory.  
Choose a directory for the website content:
```
sudo mkdir /var/www/coit13240-online1.test
```
Then set the correct ownership and permissions:
```
sudo chown -R sbrown:sbrown /var/www/coit13240-online.test
sudo chown -R 755 /var/www/coit13240-online1.test
```
These ensure the user can write files, while Apache can read them.

## 6. Add test HTML File
Create a simple test page
```
nano /var/www/coit13240-online1.test/index.html
```
I originally used this but anything can be put on the test page:
```
<!DOCTYPE html>
<html>
  <head><title>Welcome to coit13240-online1.info</title></head>
  <body><h1>It works!</h1></body>
</html>
```
Updated:
```
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Server Status - COIT13240</title>
</head>
<body>
    <h1>Server Online1 for COIT13240 - Applied Cryptography</h1>
    <p>Your web server is configured correctly and serving pages.</p>
  </div>
</body>
</html>
```
![image](https://github.com/user-attachments/assets/026715f9-1cad-4b9b-b790-e2baf9c8b979)

## 7. Configure Apache Virtual Host

Tell Apache to serve the site by creating a virtual host config:
```
sudo nano /etc/apache2/sites-available/coit13240-online1.test.conf
```
Add this:
```
<VirtualHost *:80>
    ServerName coit13240-online1.info
    ServerAlias www.coit-online1.info
    DocumentRoot /var/www/coit-online1.test

    <Directory /var/www/coit-online1.test>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/coit13240-online1.test_error.log
    CustomLog ${APACHE_LOG_DIR}/coit13240-online1.test_access.log combined
</VirtualHost>
```
ServerName is the domain name that was configured in [Domain Name To Cloud VM Provider Setup Guide](./DomainNameToCloudVMProviderSetupGuide.md)

## 8. Enable the site and Reload Apache
Activate the new config and disable the default one:
```
sudo a2ensite coit13240-online1.test.conf
sudo a2dissite 000-default.conf
sudo systemctl reload apache2
```
Use this code to validate the config if Apache won't reload:
```
sudo apache2ctl configtest
```
If it returns with "Synax OK", then restart apache:
```
sudo systemctl restart apache2
```
If it returns with errors, go back into the virtual host file and fix any typos

## 9. Secure Site with HTTPS
Make sure the domain's DNS is set up to point to the server's IP. The information for how to do that can be found in [Domain Name To Cloud VM Provider Setup Guide](./DomainNameToCloudVMProviderSetupGuide.md)    
Install certbot:
```
sudo apt install certbot python3-certbot-apache
sudo certbot --apache
```
Input the email address you want notifications to go to, answer two questions, and choose the domain to be redirected to HTTPS. The certificate and key will be saved in:
```
/etc/letsencrypt/live/coit13240-online1.info
```
Test the webserver:
```
https://coit13240-online.info
```
The information from index.html should be dislayed.

This information was gathered from the [Certbot](https://certbot.eff.org/) documentation, directed from [Let's Encrypt](https://letsencrypt.org/getting-started/).

## 10. Common Error: DNS Not Resolving?
Verify your A record by using DNS checkers like [DNS Checker](https://dnschecker.org) to confirm propogation. It can take serveral hours, but ticks should start to appear after 10 minutes. 

The next step is to improve upon the default security provided by Apache. Find the information in [Apache Web Server Security Hardening Guide](./ApacheWebServerSecurityHardeningGuide.md)
