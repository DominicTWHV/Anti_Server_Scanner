#!/bin/bash

#path to your velocity latest.log file
LOG_FILE="/path/to/your/logs/latest.log"

#path to your desired txt output file, only used when BLOCK_IP is set to false
IP_LOG_FILE="/path/to/suspicious_ips.txt"

#set to true if you want automatic actions and append it into iptables, and set to false if you want to create a txt file for them
BLOCK_IP=false

#which versions are accepted (will not create an entry in iptables/log file if defined here or in range)
MIN_VERSION="1.19.1"  #minimum version permitted before creating an entry
MAX_VERSION="1.21"    #maximum version permitted before creating an entry

#when either option is null, the other option's version will be used (no range, so only a single version will be permitted)

#whether to permit "Unknown" versions, recommended to set this to false
PERMIT_UNKNOWN=false

#compare versions
version_lt() { 
    [ "$1" != "null" ] && [ "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1" ]; 
}

version_gt() { 
    [ "$1" != "null" ] && [ "$(printf '%s\n' "$@" | sort -V | tail -n 1)" != "$1" ]; 
}

#read log file to check
grep "is pinging the server with version" "$LOG_FILE" | while read -r line; do
  #extract ip
  ip=$(echo "$line" | grep -oP '(?<=/\[)[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(?=:)' )
  version=$(echo "$line" | grep -oP '(?<=version )[0-9\.]+|Unknown')

  #determine if permitted
  allow_ip=false

  if [ "$version" == "Unknown" ]; then
    if [ "$PERMIT_UNKNOWN" = true ]; then
      allow_ip=true
    fi
  else
    if [ "$MIN_VERSION" == "null" ] && [ "$MAX_VERSION" == "null" ]; then
      #specific version? need exact match
      if [ "$version" == "$MAX_VERSION" ]; then
        allow_ip=true
      fi
    else
      #check if within range
      if ! version_lt "$version" "$MIN_VERSION" && ! version_gt "$version" "$MAX_VERSION"; then
        allow_ip=true
      fi
    fi
  fi

  #not allowed, process ip
  if [ "$allow_ip" = false ]; then
    #check iptables entry or in log file
    if ! iptables -L INPUT -v -n | grep -q "$ip"; then
      if [ "$BLOCK_IP" = true ]; then
        # Block the IP using iptables
        echo "Blocking IP: $ip with version $version"
        iptables -A INPUT -s "$ip" -j DROP
      else
        #append to logs if not present
        if ! grep -q "$ip" "$IP_LOG_FILE"; then
          echo "Logging IP: $ip to $IP_LOG_FILE"
          echo "$ip" >> "$IP_LOG_FILE"
        else
          echo "IP $ip is already logged."
        fi
      fi
    else
      echo "IP $ip is already blocked."
    fi
  fi
done
