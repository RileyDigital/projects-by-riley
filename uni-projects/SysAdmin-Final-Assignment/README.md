[Return to Index](../)  
[Return to SysAdmin-Final-Assignment](./)

# Sysadmin Final Assignment - Solo Implementation

Type: University Practical Project  
Role: Independeant Sysadmin & Security Engineer   
Grade: Distinction     
Course: COIT13146 System & Network Administration (Final Assignment)  

## Overview
This project represents the capstone of my Sysadmin course, designed to demonstrate the application of skills learned through the semester in a realistic small business network scenario.

Though this was a group assignment, I was the sole implementer of the project, delivering what was required for the fictional software development startup "CQuNix", consisting of 10 full-time employees and up to 10 part-time/contract staff. The project involved designing, deploying, securing, and testing all central infrastructure servers in a virtualised environment. 

The scope included:
- Internal network design including DHCP, NAT, and firewall.
- Server deployment for web, SSH, Git, backup, and router services.
- Backup automation and recovery procedures.
- Security hardneing, password policies, and auditing.
- HTTPS and SSL certificate management.
- Testing and documentation for maintainability and usability.

## Scenario Summary
The company requires the following servers (all Ubuntu-based):
- adelaide: Apache web server with PHP/Dokuwiki for internal documentation
- sydney: SSH server for code compilation and access for all staff
- gladstone: Git server to replace external repositories
- bundaberg: Backup server for all critical services with timestamped file lists
- darwin: DHCP server for dynamic IP allocation to workstations and laptops
- rocky: Gateway router performing NAT and firewall duties
Each server was configured on separate virtual machines within an internal network. Assumptions were made for workstations and laptops for testing purposes, but only one of each and servers were implemented and assessed.

## Key Contributions
### Network & Server Design
- Created a detailed network diagram with labelled servers, MAC addresses, and IP allocations.
- Designed internal network topology with NAT, firewall rules, and DHCP configurations.
### Server Deployment & Configuration
- Implemented Apache, SSH, and Git servers with proper user access and authentication.
- Hardened servers for security, including password aging and account policies.
### Backup & Recovery
- Developed automated backup scripts with timestamped file lists and owner details.
- Documented recovery instructions for inexperienced staff.
- Synchronised Dokuwiki pages via Git to the backup server.
### Security & Auditing
- Implemented iptables firewall rules to secure internal network while allowing essential traffic.
- Configured SSH login auditing and optional IP blocking for failed attempts.
- Managed HTTPS and certificate configuration on web server
### Testing & Verification
-  Validated network connectivity, DHCP assignment, and firewall access rules.
-  Tested automaated backups and recovery procedures.
-  Verified secure account configurations and server hardening.
### Documentation & Presentation
- Authored detailed progress reports, reflections and setup guides.
- Recorded presentation highlighting technical implementation and demonstrations
- Watch the final presentation here: [Final Presentation](https://youtu.be/ToNZFXUfcWw)

