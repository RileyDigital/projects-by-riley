# Secure Web App Report

[Return to Index](../)  
[Return to Web](./)

Type: University Practical Project  
Role: Sysadmin & Security Engineer  
Grade: High Distinction (Full Marks)  
Course: COIT13240 - Applied Cryptography (Security Project)  
Responsibilities:  
- Configured and secure an Apache web server on a Linux VM
- Implemented HTTPS with SSL Certificates
- Set up user authentication, firewall rules, and SSH key access
- Configured a reverse proxy to route traffic securely
- Deployed version-controlled content via Git
- Documented server setup and security steps

## Design

The web server setup was designed to balance security with necessary legacy compatibility, reflecting realistic production constraints. Two HTTPS virtual hosts were configured on port 443, each with distinct security profiles:
* **Secure HTTPS version**: Enforces modern TLS standards (TLS 1.2 minimum) and strong cipher suites, excluding `MD5`, `3DES` and `RC4`, prioritising security and compatibility (OWASP Transport Layer Security Cheat Sheet 2025).
* **Insecure HTTPS version**: Allows TLS 1.2, as older TLS protocols lead to the browser rejecting the connection, and weaker cipher suites for compatibility testing or legacy client support.

Both versions serve different purposes: the secure host ensures best practice security for most users and an HTTP virtual host on port 80 maintained solely to redirect traffic to the secure HTTPS site, discouraging unencrypted access,
while the insecure host provides a controlled environment demonstrating legacy risks and protocol weaknesses. 

Key design choices include:
* **Separate HTTPS Virtual Hosts on port 443**: One with strict security parameters, the other with intentionally weaker protocols and ciphers to illustrate the security trade-offs.
* **TLS 1.2 enforcement with selective cipher suites**: TLS 1.2 was chosen as a minimum to ensure strong encryption without breaking compatibility with older clients. Cipher suites were carefully selected to include secure, wildly supported options while exluding depreciated and insecure ciphers. As found while configuring the insecure version, Apache will fail to start with unsupported cipher configurations, so practical tuning was necessary to maintain uptime. 
* **Hiding server details**: `ServerTokens` was set to Prod and `ServerSignature` to Off to reduce the server's fingerprint in response headers and error pages. This practice mitigates information leakage that attackers could exploit to target specific Apache versions or modules (Apache Software Foundation 2025).
* **FileETag disabled**: Setting `FileETag None` disables generation of filesystem metadata (such as inode numbers), in ETag headers, preventing potential cache poisoning or server fingerprinting attacks (Apache Software Foundation 2025).

**Reverse Proxy**  

An Apache reverse proxy was implemented to separate frontend security from backend logic, reflecting modern best practices in secure web architecture. All HTTPS traffic is terminated at the proxy, which forwards requests to the internal Flask service on port `5000`.

Key benefits:

* **TLS Termination**: Apache handles all certificate-based encryption, simplifying backend deployment and centralising security.
* **Request Forwarding**: `ProxyPass` and `ProxyPassReverse` route traffic cleanly to the backend, isolating it from direct exposure.
* **Simplified Security**: Only ports 80/443 are externally open, reducing attack surface. Backend ports remain internal.
* **Security Enforcement**: TLS settings and HTTP headers (HSTS, CSP, etc.) are enforced at the proxy level, ensuring consistent client protections.

The layered approach supports maintainability, secure defaults, and production-aligned design. 

## Build

The Apache web server was configured through a series of steps to implement a secure and insecure design while preserving operational stability.

**Secure:**
* **A secure combined HTTP/HTTPs virtual host**: Editing the file created by Certbot with Let's Encrypt [certificate](./fullchain.pem), the HTTP section permanently redirects all HTTP traffic to the HTTPS site using the Redirect permanent directive. This guarantees encrypted access to content while maintaining backward compatibility. The HTTPS section points to valid certificate and key file. File paths were verified and their permissions locked down to restrict unauthorised reading (Let's Encrypt 2025; Electronic Frontier Foundation 2025).
* **Security Headers**: The [security-secure.conf](./security-secure.conf) included these headers: 
  * **Strict-Transport-Security (HSTS)**: Enforces HTTPS by instructing browsers to only access the domain (and subdomains) via secure connections for two years. This prevents downgrade attacks and SSL stripping attempts.
      * *Trade-off*: Once enabled, browsers will refuses to connect over HTTP, which means any misconfiguration could lock out users. Also, HSTS requires HTTP to be correctly configured and certificates to be valid, or users will face errors. 
  * **X-Content-Type-Options**: Prevent MIME sniffing by forcing browsers to honour declared content types. This reduces the risk of malicious content being interpreted incorrectly, which can lead to injection attacks.
      * *Trade-off*: Overly strict enforcement may cause some legitimate content to break if MIME types are misconfigured.
  * **X-Frame-Options**: Set to DENY to prevent the site from being embedded in frames or iframes. This defends against clickjacking attacks where a malicious site tricks users into clicking hidden elements.
      * *Trade-off*: Legitimate users of iframes for embedding content or widgets from the same site or trusted domains will be blocked unless exceptions are carefully configured.
  * **Referrer-Policy**: Controls what referral data browsers send to third-party sites, limiting uncessary data leakage and improving user privacy.
      * *Trade-off*: Some analytics or third-party integrations relying on full referrer URLs may see reduced data, but user privacy generally outweighs this.
  * **Content-Security-Policy (CSP)**: Defines strict rules about where content such as scripts and styles can be loaded from, significantly reducing cross-site scripting (XSS) and code injection vulnerabilities.
      * *Trade-off*: A script CSP can break third-party content like analytics, widgets, or external fonts/styles unless explicitly allowed. Implementing CSP requires thorough testing and possibly fine-tuning to avoid unintentionally blocking legitimate content.  
       All security headers content was found in [OWASP Secure Headers Project](https://owasp.org/www-project-secure-headers/)
* **Cipher Suites**: In the [coit13240-secure.conf](./coit13240-secure.conf) the SSL cipher suite was carefully tuned to balance security and compatibility. TLS 1.2 was enforced with suites prioritising `AES_GCM` (OWASP Transport Layer Security Cheat Sheet 2025). 
* **Permissions**: Let's Encrypt certificate files and directories were locked down with both chmod and chown settings, ensuring only root and Apache can read sensitive files (Apache Software Foundation 2025).

**Insecure**:
* **An insecure combined HTTP/HTTPS virtual host**: The [coit13240-insecure.conf](./coit13240-insecure.conf) strictly enforces TLS 1.2 and accepts all ciphers. Deprecated suites caused Apache startup failures, so moderate settings were adopted to maintain service availability.
* **Insecure Security**: The [security-insecure.conf](./security-insecure.conf) illustrates these common security pitfalls:
    * **No Security Headers**: Lacking `HSTS`, `CSP`, or `X-Frame-Options` leaves the server open to downgrade attacks, code injection, and clickjacking.
    * `FileETag All`: Exposes inode and file metadata, aiding fingerprinting and cache-based attacks.
    * `ServerTokens Full` and `ServerSignature On`: Reveals detailed server and OS version info making targeted attacks easier.
    * `TraceEnable On`: Allows HTTP TRACE, enabling Cross Site Tracing (XST) when combined with XXS.
 
 This baseline configuration helped contrast the hardened setup and reinforced how small changes can significantly reduce risk. 

**Reverse Proxy Configuration**:  

A reverse proxy was implemented using Apache to securely expose the Flask-based web application while maintaining a clear separation between web server responsibilities and application logic. This setup allows Apache to handle HTTPS traffic, apply relevant security headers, and forward requests internally to the application running on port `5000`.

The Apache `mod_headers` module was enabled, if not enabled by default, to add essential HTTP security headers that harden client-side protections, as well as `mod_proxy` and `mod_proxy_http` (Apache Software Foundation 2025). 
* `mod_proxy` provides the basic proxy functionality.
* `mod_proxy_http` enables proxying of HTTP requests to backend servers.

After enabling these modules, restart Apache to apply the changes:
```
sudo systemctl restart apache2
```
The following directives were configured within the virtual hosts:
```
ProxyPreserveHost On
ProxyPass / http://4.237.69.200:5000/
ProxyPassReverse / http://4.237.69.200:5000/
```
**Explanation of Directives**:

* **ProxyPreserveHost On**: This directive ensures that the original `Host` header sent by the client is retained when the request is forwarded to the backend application. This is essential for applications that generate domain-specific URLs to perform logic based on the incoming domain name.
* **ProxyPass / http://4.237.69.200:5000/**: This maps all incoming client requests at the root path (`/`) to the Flask application running on `4.237.69.200` port `5000`. Apache handles SSL termination and forwards only the HTTP request internally, keeping the application decoupled from TLS responsibilities.
* **ProxyPassReverse / http://4.237.69.200:5000/**: This modifies response headers from the backend application, particularly redirects, so that they point to the public-facing domain instead of the internal server address. Without this, client-side redirects could incorrectly expose or rely on internal hostnames or IPs.

**Trade-Offs**:

* **Increased Configuration Complexity**: Introducing a reverse proxy adds an additional layer to the infrastructure, which can complicate troubleshooting and require more careful configuration to ensure seamless communication between proxy and backend.
* **Performance Overhead**: SSL termination and HTTP proxying consume CPU and introduce slight latency, which can impact response times, especially under high traffic loads or limited hardware resources.
* **Single Point of Failure**: If the reverse proxy goes down or is misconfigured, it can block all access to the backend services, creating a critical failure point unless redundancy is implemented.

Explanatation and trade offs dervied from [Apache mod_proxy documentation](https://httpd.apache.org/docs/2.4/mod/mod_proxy.html).
  
### How To Reproduce

* [Apache Web Server Setup Guide](./ApacheWebServerSetupGuide.md)
* [Domain Name To Cloud VM Provider Setup Guide](./DomainNameToCloudVMProviderSetupGuide.md)
* [Apache Web Server Security Hardening Guide](./ApacheWebServerSecurityHardeningGuide.md)

## Testing

The security configuration was validated through rigorous testing: 
* **Apache Syntax and Logs**: All configuration files passed syntax checks. System logs were monitored for errors during startup and reload.
* **Browser Testing**: Accessing the HTTP URL correctly redirected to HTTPS with no redirect loops or errors, ensuring usability and security enforcement.
* **External Scans**: Mozilla Observatory assesessments provided objective security scores and vulnerability reports. The final secure configuration achieved a strong rating, demonstrating the effectiveness of hardening measures.
* **Packet Capture**: Wireshark was used to capture network traffic during the client-server TLS handshakes for both secure and insecure configurations. Although the insecure server allowed all cipher suites (including weaker ones), the client consistently negotiated strong TLS 1.2 cipher suites, demonstrating client-side preference for secure connections when available. This highlights that server leniency on cipher suites can expose risks if clients don't enforce strong policies themselves. The captures validated successful encrypted communication and certificate exchanges. While decrypting traffic was limited by the absence of SSL key logging, these packet captures provide evidence of encryption protocols in action.
* **Issue Resolution**: Common issues encountered included redirect loops caused by overlapping rewrite rules and Apache failing to start due to unsupported cipher suites. These were resolved through configuration refinement and iterative testing.

## Protocols

The webserver uses HTTPS over TLS 1.2 to ensure encrypted communication between clients and server. The decision to enforce TLS 1.2 as the minimum supported version reflects a balance between modern cryptographic strength and broad client compatibility. TLS 1.3 was not enforced due to potential issues with legacy client support and occasional incompatibility with intermediate proxies or inspection tools (OWASP Transport Layer Security Cheat Sheet 2025). 

**TLS Handshake**  

When a client connects to the server, a TLS handshake is initiated to negotiate encryption settings and establish a secure session. The handshake process is as follows:  
* The client sends a **ClientHello**, which includes supported TLS versions, cipher suites, and extensions
* The server responds with a **ServerHello**, selecting the TLS version and cipher suite to be used
* The server also sents its **certificate**, issued by Let's Encrypt, to authenticate itself to the client
* The key exchange occurs (via ephemeral Diffie-Hellman/ECDHE), establishing a shared session key
* Both client and server send **Finished** messages encrypted with the newly agreed key, completing the handshake
* All application data (such as HTTP responses) is encrypted using the negotiated cipher suite
* [Link to Sequence Diagram](./sequencediagramweb.md)

This process ensures confidentiality, authentication, and message integrity over the entire session.

**Capture Validation**

A packet capture was performed using Wireshark to validate the handshake and encryption. The captured traffic confirms that the server correctly negotiates TLS 1.2 with strong cipher suites (e.g. `ECDHE_RSA_AES128_GCM_SHA256`) on the secure host, while the insecure host allows a broader range of suites for demonstration and stability purposes.  
* [Link to secure packet capture](./servercapturesecure.pcapng)
* [Screenshot: secure ClientHello](./screenshots/ClientHellosecure.png)
* [Screenshot: secure ServerHello](./screenshots/ServerHellosecure.png)
* [Link to insecure packet capture](./servercaptureinsecure.pcapng)
* [Screenshot: insecure ClientHello](./screenshots/ClientHelloinsecure.png)
* [Screenshot: insecure ServerHello](./screenshots/ServerHelloinsecure.png)
* [Screenshot: insecure Certificate](./screenshots/Certificateinsecure.png)

In the packet captures comparing the secure config and the insecure config allowing all cipher suites, the insecure server surpisingly negotiated `TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384` (TLS 1.2). The secure server negotiated `TLS_AES_128_GCM_SHA256` (TLS 1.3). Even though the insecure server's cipher looks stronger due to the 256-bit key and ECDSA, TLS 1.3's streamlined design provides better overall security by enforcing forward secrecy, eliminating broken ciphers, and simplifying cipher negotiation. This case highlights how protocol versions matter more than cipher name alone and demonstrates that allowing all cipher suites can lead to unpredictable cipher negotiation outcomes that can be surprisingly strong, but ultimately lacking the intentional control needed for consistent security. 

**Cipher Suites**

Secure host: 

* The secure config explicitly restricts cipher suites and protocols to enforce strong encryption standards, reflected in the use of `SSLCipherSuite HIGH:!aNULL:!MD5:!3DES:!RCA`.
This prioritises high-strength ciphers while excluding known weak algorithms such as `aNULL`, `MD5`, `3DES` and `RC4`, which have documented security flaws (OWASP Transport Layer Security Cheat Sheet 2025).

Insecure host:

* Accepts all suites including `AES128_SHA` and `DES_CBC3_SHA` for legacy testing. This was done to demonstrate weaknesses in outdated configuration and stability of the web server. This is not recommended for production environments. 

**HTTP to HTTPS**

Unecrypted HTTP (port 80) is used solely to redirect clients to HTTPS. This behaviour was verified through browser testing and packet captures. The redirect mechanism prevents unecrypted content exposure while preserving user accessibility for older bookmarks or manual HTTP entires.

**Reverse Proxy**
* TLS encryption is terminated at the reverse proxy, which handles SSL/TLS handshakes using the server's certificate.
* This offloads encryption/decryption from backend services, allowing internal HTTP communication.
* The proxy enforces HTTPS for all external client connections, centralising certificate management.

## Analysis

The final web server configuration represents a balance between modern security standards and real-world usability constraints:

**Security Benefits**:
 
* **Layered Defences**: HSTS enforces encrypted communications overtime, reducing downgrade risks. `CSP` and `X-Frame-Options` mitigate XSS and clickjacking. Disabling `ServerTokens`, `ServerSignature`, and `FileETag` limits attacker reconnaissance and reduces the surface for cache poisoning or fingerprinting (Apache Software Foundation 2025).
* **Permissions Hardening**: TLS certificate and key files are protected with strict file-level permissions (`600`), reducing exposure risk from local privilege escalation.
* **Reverse Proxy Use**: Centralised SSL termination behind a hardened reverse proxy improves manageability and isolates cryptographic conerns from application logic.
* **Testing Rigor**: Browser-based, command-line, and packet-level testing validated TLS negotiation, redirect behaviour, and header enforcement. IT also revealed how much TLS debugging relies on direct access to keys or SSL logging.
 
**Trade-Offs**:

* **TLS 1.2 Support**: TLS 1.3 provides performance and security improvements (like forward secrecy by default), but limiting it exclusively would lock out legacy clients. Supporting 1.2 maintains wider compatibility, a necessary compromise for production (OWASP Transport Layer Security Cheat Sheet 2025).
* **Cipher Suite Flexibility**: Attempting to enforce only high-security cipher suites initially caused Apache startup failures and browser rejection. Falling back to a broader but still vetted set ensured uptime, demonstrating how misconfigurations can create denial-of-service scenarios even before an attack.
* **Legacy HTTP Handling**: Maintaining a non-secure virtual host for redirect purposes creates a soft target. If redirects are misconfigured or caching interferes, users may stay on HTTP unintentionally.

**Reverse Proxy**:

The Apache reverse proxy terminates all HTTPS traffic, centralising TLS management and improving both security and maintainability:
* **Security Header Enforcement**: The reverse proxy consistently applies HTTP security headers (e.g., `Content-Security-Policy`, `Strict-Transport-Security`, `X-Content-Type-Options`, `X-Frame-Options`), even if backend apps forget or misconfigure them.
* **TLS Offloading and Cipher Control**: Control which TLS and cipher suites are accepted without requiring changes in backend services, and ensure weak protocols are rejected.
* **Protocol Translation**: Handles client requests over HTTP/2 or HTTP/3 and translate to HTTP/1.1 for backend compatibility. This allows newer browser features without requiring changes to older applications.

Information about reverse proxy derived from [Apache mod_proxy Module](https://httpd.apache.org/docs/2.4/mod/mod_proxy.html) documentation. 

**Lessons Learned**:
* **Layered Defences**: Immplementing HSTS, CSP, strict cipher suites, and header hardening creates multiple hurdles for attackers. Relying on just one control is a recipe for failure.
* **Protocol Balance**: Supporting TLS 1.2 alongside TLS 1.3 maximises client compatibility but requires ongoing monitoring to phase out older protocols as threats evolve.
* **Operational Discipline**: Automated certificate renewal, strict file permissions, and detailed logging are non-negotiable to maintain security over time. Manual processes invite mistakes.
* **Thorough Testing**: Using tools like Mozilla Observatory and Wireshark uncovers hidden issues that basic configuration checks miss, highlighting the importance of continuous validation.
* **Attention to Detail**: Misconfigurations in redirects, cipher suite selection, or info exposure, even minor ones, can lead to critical vulnerabilities and must be carefully managed.
* **Legacy Support**: Providing an insecure host for legacy clients balances usability with security risks, but it demands clear separation and careful monitoring to avoid accidental exposure.  

## Setup Details

* Web server: Apache2  
* OS: Ubuntu 24.04 LTS
* Domain name: coit13240-online1.info  
* SSL: Enabled via Let's Encrypt using Certbot  
* Firewall: Managed via UFW  
* Ports open: 80 (HTTP), 443 (HTTPS)

### Security Score
* Tested with [Mozilla HTTP Observatory](https://developer.mozilla.org/en-US/observatory)
* Default score: 30/100  
* Secure score: 110/100
* Insecure score: 10/100

### References

* Gordon, S & Wang, Z 2025. *Deploying a Web Server*, COIT13146: System and Network Administration [Workshop], Week07.
* Let's Encrypt 2025. *Getting Started with Let's Encrypt*. Available at: https://letsencrypt.org/getting-started/  
* Electronic Frontier Foundation 2025. *Certbox - Easy SSL/TLS Certificates*. Available at: https://certbot.eff.org/  
* OWASP 2025. *Transport Layer Security Cheat Sheet*. Available at: https://cheatsheetseries.owasp.org/cheatsheets/Transport_Layer_Security_Cheat_Sheet.html  
* OWASP 2025. *Secure Headers Project*. Available at: https://owasp.org/www-project-secure-headers/  
* Apache Software Foundation 2025. *Apache HTTP Server Documentation*. Available at: https://httpd.apache.org/docs/current/mod/core.html
* Apache Software Foundation 2025. *Apache Module mod_proxy*. Available at: https://httpd.apache.org/docs/2.4/mod/mod_proxy.html

