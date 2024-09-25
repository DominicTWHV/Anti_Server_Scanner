#!/bin/bash

#path to your latest.log for velocity
LOG_FILE="/path/to/ur/logs/latest.log"

#path for the file to generate when BLOCK_IP is set to false
IP_LOG_FILE="/path/to/ur/suspicious_ips.txt"

#set to true if you want automatic actions and append it into iptables, and set to false if you want to create a txt file for them
BLOCK_IP=false

#define what versions are whitelisted. It's recommended that you only permit versions that your server is on, ie 1.21
PERMITTED_VERSIONS=("1.21" "1.19") #as example

#set to true to permit 'Unknown' versions, recommended value = false, as unknown is most often seen with scanners
PERMIT_UNKNOWN=false


#=================DO NOT TOUCH BELOW UNLESS YOU KNOW WHAT YOU ARE DOING=================


#define color codes for colorful echo!
RED='\033[0;31m'    #red
GREEN='\033[0;32m'  #green
YELLOW='\033[0;33m' #yellow
BLUE='\033[0;34m'   #blue
NC='\033[0m'        #no color

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

#read log file and extract lines
grep "is pinging the server with version" "$LOG_FILE" | while read -r line; do
    #extract ip
    ip=$(echo "$line" | grep -oP '(?<=/)[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(?=:)')
    
    #extract version
    version=$(echo "$line" | sed -n 's/.*pinging the server with version //p')

    #debugging outputs, disabled for the sake of your eyes
    
    #echo -e "${YELLOW}Extracted Line: '${GREEN}$line${NC}'"
    #echo -e "${YELLOW}Extracted IP: '${GREEN}$ip${NC}'"
    #echo -e "${YELLOW}Extracted Version: '${GREEN}$version${NC}'"

    #determine if permitted
    allow_ip=true  #assume allowed initially

    if [ -z "$version" ]; then
        echo -e "${RED}No version found for IP ${GREEN}$ip.${NC}"
        allow_ip=false  #not allow if version does not match
    elif [ "$version" == "Unknown" ]; then
        echo -e "${YELLOW}Detected 'Unknown' version for IP ${GREEN}$ip${NC}."
        if [ "$PERMIT_UNKNOWN" = false ]; then
            allow_ip=false  #not allow if unknown versions are not allowed
            echo -e "${RED}IP ${GREEN}$ip ${RED}has an Unknown version and is not permitted.${NC}"
        else
            echo -e "${GREEN}IP ${GREEN}$ip ${GREEN}is allowed because Unknown versions are permitted.${NC}"
        fi
    else
        #check if version in list
        version_permitted "$version"
        if ! version_permitted "$version"; then
            allow_ip=false  #disallow if not permitted
            echo -e "${RED}IP ${GREEN}$ip ${RED}with version ${GREEN}$version ${RED}is not in the permitted version list.${NC}"
        else
            echo -e "${GREEN}IP ${GREEN}$ip ${GREEN}with version ${GREEN}$version ${GREEN} is permitted.${NC}"
        fi
    fi

    #if not allowed, process below
    if [ "$allow_ip" = false ]; then
        echo -e "${YELLOW}Processing blocked IP: ${GREEN}$ip${NC}"
        #check if already flagged in logs or iptables
        if ! iptables -L INPUT -v -n | grep -q "$ip"; then
            if [ "$BLOCK_IP" = true ]; then
                #if use iptables, block it (drop)
                echo -e "${RED}Blocking IP: ${GREEN}$ip ${RED}with version ${GREEN}$version${NC}"
                iptables -A INPUT -s "$ip" -j DROP
            else
                #append to list if iptables arent used
                if ! grep -q "$ip" "$IP_LOG_FILE"; then
                    echo -e "${BLUE}Logging IP: ${GREEN}$ip ${BLUE}to $IP_LOG_FILE${NC}"
                    echo "$ip" >> "$IP_LOG_FILE"
                else
                    echo -e "${YELLOW}IP ${GREEN}$ip ${YELLOW}is already logged.${NC}"
                fi
            fi
        else
            echo -e "${YELLOW}IP ${GREEN}$ip ${YELLOW}is already blocked.${NC}"
        fi
    else
        echo -e "${GREEN}IP: ${GREEN}$ip ${BLUE}Traffic Permitted.${NC}"
    fi
    echo
    echo -e "${GREEN}==============================================================${NC}"
    echo
done
