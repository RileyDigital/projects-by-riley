# Connect Domain Name to Cloud VM Provider Step-By-Step Guide

For these examples, I will be using Dynadot and DigitalOcean

### What You'll Need:
* A purchased domain name. I used [Dynadot](https://www.dynadot.com/)
* A running Cloud VM. I used [DigitalOcean](https://www.digitalocean.com/)
* The Cloud VMs public IP (e.g., 209.38.88.129)
* Access to both accounts

### 1. Set Name Servers on Domain Name Provider (Dynadot)
1. Go to the control panel
2. Go to "My Domains" > "Manage Domains"
3. Click on domain name (e.g., coit13240-online1.info)
4. Scroll to "Name Servers", and choose "Name Servers", from the dropdown
5. Enter DigitalOcean's default name servers:
```
ns1.digitalocean.com  
ns2.digitalocean.com  
ns3.digitalocean.com
```
6. Click "Save Name Server"  
DNS changes can take up to 48 hours to fully propogate, but it usually happens much faster.

### 2. Configure DNS on Cloud VM Provider (DigitalOcean)
1. Go to the networking dashboard
2. Click "Domains", then "Add Domain"
3. Enter full domain name:
```
coit13240-online1.info
```
4. Click "Add Domain"  
This will direct to the DNS settings.

### 3. Add A Records  

coit13240-online1.info
* Hostname: @
* Will Direct To: 209.38.88.129
* TTL: Default  
Click "Create Record"

www.coit13240-online.info
* Hostname: www
* Will Direct To: 209.38.88.129
* TTL: Default  
Click "Create Record"    
This creates two A records that point to the same IP address. 
