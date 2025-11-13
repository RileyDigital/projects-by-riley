#!/bin/bash
# Interal: enp0s3 | External: enp0s8

# Allow IP forwarding
echo "Enabling IP forwarding..."
grep -q '^net.ipv.ip_forward=1' /etc/sysctl.conf || echo 'net.ipv4.ip_forward=1 >> /etc/sysctl.conf
sysctl -w net.ipv4.ip_forward

# Flush existing rules
echo "Flushing existing iptables rules..."
iptables -F
iptables -t nat -F

# Allow loopback
echo "Allowing loopback interface..."
iptables -A INPUT -i lo -j ACCEPT

# Allow SSH from internal network
echo "Allowing SSH to router..."
iptables -A INPUT -p -tcp --dport 22 -j ACCEPT

# Allow established/related traffic
echo "Allowing related and established connections..."
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# Forward traffic from internal to external
echo "Allowing forward from internal to external"
iptables -A FORWARD -i enp0s3 -o enp0s8 -j ACCEPT

# Allow SSH forwarding
echo "Allowing SSH forwarding..."
iptables -A FORWARD -p tcp --dport 22 -j ACCEPT

# Forward HTTP and HTTPS to adelaide (web server at 192.168.100.3)
echo "Allowing nat and forward for HTTP and HTTP..."
iptables -t nat -A PREROUTING -i enp0s8 -p tcp --dport 80 -j DNAT --to-destination 192.168.100.3:80
iptables -t nat -A PREROUTING -i enp0s8 -p tcp --dport 443 -j DNAT --to-destination 192.168.100.3:443
iptables -A FORWARD -p tcp -d 192.168.100.3 --dport 80 -j ACCEPT
iptables -A FORWARD -p tcp -d 192.168.100.3 --dport 443 -j ACCEPT

# Enable nat (Masquerade) for outbound traffic from internal to external
echo "Enabling masquerading for outbound traffic..."
iptables -t nat -A POSTROUTING -o enp0s8 -j MASQUERADE
# Saving iptables rules
echo "Saving iptables rules..."
sudo netfilter-persistent save

echo "Done. IP forwarding and firewall rules are in place."
