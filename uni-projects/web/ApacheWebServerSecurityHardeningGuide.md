# Apache Web Server Security Hardening Step-By-Step Guide
This guide helps secure an Apache server using best-practice configuration.

## 1. Edit Virtual Host
Edit the HTTP config that was set up in the [Apache Web Server Setup Guide](./ApacheWebServerSetupGuide.md).  
I renamed this to:
```
coit13240-secure.conf
```
```
sudo nano /etc/apache2/sites-available/coit13240-secure.conf
```
Use this config:

```
<VirtualHost *:80>
    ServerName coit13240-online1.info
    ServerAlias www.coit13240-online1.info
    DocumentRoot /var/www/coit13240-online1.test

    #Redirect to HTTPS
    Redirect permanent / https://coit13240-online1.info/
</VirtualHost>

<VirtualHost *:443>
    ServerName coit13240-online1.info
    ServerAlias www.coit13240-online1.info
    DocumentRoot /var/www/coit13240-online1.test

    SSLEngine on
    Include /etc/letsencrypt/options-ssl-apache.conf
    SSLCertificateFile /etc/letsencrypt/live/coit13240-online1.info/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/coit13240-online1.info/privkey.pem

    <Directory /var/www/coit13240-online1.test>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    SSLProtocol TLSv1.2 TLSv1.3
    SSLCipherSuite HIGH:!aNULL:!MD5:!3DES:!RC4
    SSLHonorCipherOrder on

    ErrorLog ${APACHE_LOG_DIR}/secure-error.log
    CustomLog ${APACHE_LOG_DIR}/secure-access.log combined
</VirtualHost>

```
This setup was gathered from [OWASP TLS](https://cheatsheetseries.owasp.org/cheatsheets/Transport_Layer_Security_Cheat_Sheet.html) documentation.  
`!aNull`: Prevents cipher suites that offer no authentication  
`!MD5`: Excludes MD5 which is cryptographically broken  
`!3DES`: Removes triple DES, which is vulnerable to the Sweet32 attack  
`!RC4`: Excluded due to multiple cryptographic flaws  

Enable and reload Apache2:
```
sudo a2ensite coit13240-secure.conf
sudo systemctl reload apache2
```
This validates ownership with Let's Encrypt and serves a basic site.

## 3. Hide Apache Version & Server Details
By default, Apache leaks information about its version, modules and OS in responses and error pages. Let's stop that.   
I renamed this file:
```
security-secure.conf
```
Edit the file:
```
sudo nano /etc/apache2/conf-available/security-secure.conf
```
Set:
```
ServerTokens Prod
ServerSignature Off
TraceEnable Off (default)
```
Turning ServerTokens to `Prod` hides all version and OS info, returning just "Apache". This makes it harder for attackers who scan for specific Apache versions with known vulnerabilities.  
Turning SeverSignature to `Off` removes the Apache version and server info from 403/404 pages. It can prevent casual information leaks in user-facing error pages.     
And then add to the bottom:
```
FileETag None
```
Adding FileETag None avoids any unnecessary file system exposure, caching issues, and server fingerprinting. By default, Apache can generate ETags for caching to determine if a file has changed since it was last fetched. One of the categories it can generate is "inode number". Inode numbers can sometimes break caching logic and, if exposed, can give away details about the internal structure of the server. 

These four settings were found in the [Apache Core Features](https://httpd.apache.org/docs/current/mod/core.html) documentation. 

Enable it and reload Apache:
```
sudo a2enconf security-secure.conf
sudo systemctl reload apache2
```

## 6. Add Security Headers
Security headers protect against clickjacking, MIME sniffing, XXS, and more.   
Add them to the security config:
```
sudo a2enmod headers
sudo nano /etc/apache2/conf-available/security-secure.conf
```
Add:
```
Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
Header always set X-Content-Type-Options "nosniff"
Header always set X-Frame-Options "DENY"
Header always set Referrer-Policy "strict-origin-when-cross-origin"
Header always set Content-Security-Policy "default-src 'self'; script-src 'self'; style-src 'self';"
```
* **Strict-Transport-Security** enforces HTTP by telling browsers to only access the domain and subdomains via HTTPS for the next 63072000 seconds (or 2 years). Even if http is typed in the browser, it will auto upgrade. This prevents SSL stripping and ensures secure traffic by default.
 
* **X-Content-Type-Options "nosniff"** stops browsers from "sniffing" (or guessing) content types. For example, if a site serves JavaScript with the wrong content-type, some browsers will interpret it anyway, which can lead to XSS vulnerabilities. This forces the browser to obey declared MIME types, reducing unexpected behaviour and attack vectors.
 
* **X-Frame-Options "DENY"** prevents the domain from being loaded inside an iframe on another site. This protects against clickjacking, which is a sneaky attack where users are tricked into clicking something invisible on a malicious page.
  
* **Referrer-Policy** controls what information is sent in the referrer header when a user clicks a link to another site. This helps protect user privacy and reduce data leakage to third parties.

* **Content-Security-Policy** can reduce XSS and data injection attacks by declaring where content is allowed to come from. This rule is very strict and was put in as a precaution. It may be edited later.

This was derived from the [OWASP Secure Headers Project](https://owasp.org/www-project-secure-headers/)

Reload Apache:
```
sudo systemctl reload apache2
```

## 7. Fix Permissions on Let's Encrypt Certs and Symlinks
Apache needs to access the `.pem` files, but it was found that they were world-readable. Let's secure them properly.  
Set these permissions:
```
# Set correct permissions on actual cert files
sudo chmod 644 /etc/letsencrypt/archive/coit13240-online1.test/*.pem
sudo chown root:root /etc/letsencrypt/archive/coit13240-online1.test/*.pem

# Set proper permissions on folders
sudo chmod 755 /etc/letsencrypt/archive/
sudo chmod 755 /etc/letsencrypt/archive/coit13240-online1.test/
sudo chmod 755 /etc/letsencrypt/live/
sudo chmod 755 /etc/letsencrypt/live/coit13240-online1.test/
```
The /live/ folder contains symlinks, but Apache needs to access all directories to reach the actual cert files. 

## 8. Restart Apache and Verify Everything
```
sudo systemctl restart apache2
```
Check the domain in a brower using https:// and run a security scan at [Mozilla HTTP Observatory](https://developer.mozilla.org/en-US/observatory )  
This was the rating after implementing the above security:
![image](https://github.com/user-attachments/assets/eb6055e5-b1d9-4220-b9ad-b0e109ccf860)
