#!/bin/bash
# ----------------------------------------------------------
# InternetBlocker.sh
# IOT1025 - Semester Long Assignment - Part 3
# Blocks HTTP/HTTPS for non-IT users using iptables
# Allows HTTPS  for IT users + local web server 192.168.2.3
# Blocks special ports 8003 and 1979
# Run with: sudo ./InternetBlocker.sh
# ----------------------------------------------------------
# Author: Zachary Swain
# Date: November 18, 2025
# ----------------------------------------------------------

IT_GROUP="IT"	# Group name from part 1
it_count=0	# Counter for final message

# Retrieves list of IT members
members=$(getent group "$IT_GROUP" | cut -d: -f4)

# Creates a new iptables rule for each user in the IT group
if [[ -n "$members" ]]; then
   for user in $(echo "$members" | tr ',' ' '); do
      sudo iptables -A OUTPUT -p tcp --dport 443 -m owner --uid-owner "$user" -j ACCEPT
      sudo iptables -A OUTPUT -p tcp --dport 80 -m owner --uid-owner "$user" -j ACCEPT
      ((it_count++))
   done
fi

# Local web server added as an exception
sudo iptables -A OUTPUT -p tcp --dport 443 -d 192.168.2.3 -j ACCEPT
sudo iptables -A OUTPUT -p tcp --dport 80  -d 192.168.2.3 -j ACCEPT

# Drop two special ports
sudo iptables -t filter -A OUTPUT -p tcp --dport 8003 -j DROP
sudo iptables -t filter -A OUTPUT -p tcp --dport 1979 -j DROP

# Block everyone else from the internet
sudo iptables -A OUTPUT -p tcp --dport 80  -j DROP
sudo iptables -A OUTPUT -p tcp --dport 443 -j DROP

# Final message
echo "$it_count users were granted internet access."
