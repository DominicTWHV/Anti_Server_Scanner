#!/bin/bash

#path to your latest.log for velocity
LOG_FILE="/path/to/ur/logs/latest.log"

#path for the file to generate when BLOCK_IP is set to false
IP_LOG_FILE="/path/to/ur/suspicious_ips.txt"

#set to true if you want automatic actions and append it into ipset, and set to false if you want to create a txt file for them
BLOCK_IP=false

#define what versions are whitelisted. It's recommended that you only permit versions that your server is on, i.e., 1.21
PERMITTED_VERSIONS=("1.21" "1.19") # as example

#set to true to permit 'Unknown' versions, recommended value = false, as unknown is most often seen with scanners
PERMIT_UNKNOWN=false

#set to true to permit 'Legacy' versions, recommended value = false, as unknown is most often seen with scanners
PERMIT_LEGACY=false

#=================DO NOT TOUCH BELOW UNLESS YOU KNOW WHAT YOU ARE DOING=================

#define color codes for colorful echo!
RED='\033[0;31m'    #red
GREEN='\033[0;32m'  #green
YELLOW='\033[0;33m' #yellow
BLUE='\033[0;34m'   #blue
NC='\033[0m'        #no color

#ensure the script is run as root or with sudo
if [[ "$EUID" -ne 0 ]]; then
    echo -e "${RED}Please run this script as root or with sudo.${NC}"
    exit 1
fi

#check if log file exists
if [[ ! -f "$LOG_FILE" ]]; then
    echo -e "${RED}Log file ${LOG_FILE} does not exist.${NC}"
    exit 1
fi

#check if IP log file is writable or can be created
if [[ ! -w "$IP_LOG_FILE" && ! -e "$IP_LOG_FILE" ]]; then
    echo -e "${RED}Cannot write to ${IP_LOG_FILE}. Please check file permissions.${NC}"
    exit 1
fi

#check if version is permitted
version_permitted() {
    local version="$1"
    echo -e "${BLUE}Checking if version '${GREEN}$version${BLUE}' is permitted...${NC}"
    for permitted_version in "${PERMITTED_VERSIONS[@]}"; do
        echo -e "${YELLOW}Comparing with permitted version: '${GREEN}$permitted_version${NC}'"
        if [[ "$version" == "$permitted_version" ]]; then
            echo -e "${GREEN}Version '${version}' is permitted.${NC}"
            return 0  #0 if permitted
        fi
    done
    echo -e "${RED}Version '${version}' is not permitted.${NC}"
    return 1  #1 if not permitted
}

#create ipset if it doesn't exist
if ! ipset list blacklist &>/dev/null; then
    sudo ipset create blacklist hash:ip
    echo -e "${YELLOW}Created ipset 'blacklist'.${NC}"
fi

#check if iptables rule exists to use ipset, if not, create it
if ! sudo iptables -C INPUT -m set --match-set blacklist src -j DROP &>/dev/null; then
    sudo iptables -I INPUT -m set --match-set blacklist src -j DROP
    echo -e "${YELLOW}Added iptables rule to drop packets from 'blacklist'.${NC}"
fi

#read log file and extract lines
grep "is pinging the server with version" "$LOG_FILE" | while read -r line; do
    #extract IP
    ip=$(echo "$line" | grep -oP '(?<=/)[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(?=:)')

    if [[ -z "$ip" ]]; then
        echo -e "${RED}No valid IP found in the log line: ${line}${NC}"
        continue
    fi

    #extract version
    version=$(echo "$line" | sed -n 's/.*pinging the server with version //p')

    #determine if permitted
    allow_ip=true  #assume allowed initially

    if [ -z "$version" ]; then
        echo -e "${RED}No version found for IP ${GREEN}$ip.${NC}"
        allow_ip=false  #not allowed if version does not match
    elif [ "$version" == "Unknown" ]; then
        echo -e "${YELLOW}Detected 'Unknown' version for IP ${GREEN}$ip${NC}."
        if [ "$PERMIT_UNKNOWN" = false ]; then
            allow_ip=false  #not allow if unknown versions are not allowed
            echo -e "${RED}IP ${GREEN}$ip ${RED}has an Unknown version and is not permitted.${NC}"
        else
            echo -e "${GREEN}IP ${GREEN}$ip ${GREEN}is allowed because Unknown versions are permitted.${NC}"
        fi
    elif [ "$version" == "Legacy" ]; then
        echo -e "${YELLOW}Detected 'Legacy' version for IP ${GREEN}$ip${NC}."
        if [ "$PERMIT_LEGACY" = false ]; then
            allow_ip=false  #not allow if legacy versions are not allowed
            echo -e "${RED}IP ${GREEN}$ip ${RED}has a Legacy version and is not permitted.${NC}"
        else
            echo -e "${GREEN}IP ${GREEN}$ip ${GREEN}is allowed because Legacy versions are permitted.${NC}"
        fi    
    else
        #check if version is in the list
        if version_permitted "$version"; then
            allow_ip=true
            echo -e "${GREEN}IP ${GREEN}$ip ${GREEN}with version ${GREEN}$version ${GREEN}is permitted.${NC}"
        else
            allow_ip=false  #disallow if not permitted
            echo -e "${RED}IP ${GREEN}$ip ${RED}with version ${GREEN}$version ${RED}is not in the permitted version list.${NC}"
        fi
    fi

    #if not allowed, process below
    if [ "$allow_ip" = false ]; then
        echo -e "${YELLOW}Processing blocked IP: ${GREEN}$ip${NC}"
        #block or log the ip (see above)
        if [ "$BLOCK_IP" = true ]; then
            #if using ipset, block it (add to ipset)
            if sudo ipset add blacklist "$ip" 2>/dev/null; then
                echo -e "${RED}Blocking IP: ${GREEN}$ip ${RED}with version ${GREEN}$version${NC}"
            else
                echo -e "${YELLOW}IP ${GREEN}$ip ${YELLOW}is already blocked.${NC}"
            fi
        else
            #append to list if ipset isn't used
            if ! grep -q "$ip" "$IP_LOG_FILE"; then
                echo -e "${BLUE}Logging IP: ${GREEN}$ip ${BLUE}to $IP_LOG_FILE${NC}"
                echo "$ip" >> "$IP_LOG_FILE"
            else
                echo -e "${YELLOW}IP ${GREEN}$ip ${YELLOW}is already logged.${NC}"
            fi
        fi
    else
        echo -e "${GREEN}IP: ${GREEN}$ip ${BLUE}Traffic Permitted.${NC}"
    fi
    echo
    echo -e "${GREEN}==============================================================${NC}"
    echo
done
