#!/bin/bash

#colorful echo!
RED='\033[0;31m'    #red
GREEN='\033[0;32m'  #green
YELLOW='\033[0;33m' #yellow
BLUE='\033[0;34m'   #blue
NC='\033[0m'        #no color

#ask for file path
echo -e "${BLUE}Please enter the file path containing IP addresses:${NC}"
read -r file_path

#check if file exists
if [[ ! -f "$file_path" ]]; then
    echo -e "${RED}Error: File does not exist.${NC}"
    exit 1
fi

#check if ipset exists, if not, create it
if ! ipset list blacklist &>/dev/null; then
    sudo ipset create blacklist hash:ip
    echo -e "${YELLOW}Created ipset 'blacklist'.${NC}"
fi

#check if iptables rule exists, if not, create it
if ! sudo iptables -C INPUT -m set --match-set blacklist src -j DROP &>/dev/null; then
    sudo iptables -I INPUT -m set --match-set blacklist src -j DROP
    echo -e "${YELLOW}Added iptables rule to drop packets from 'blacklist'.${NC}"
fi

#read IP addresses line by line
while IFS= read -r ip; do
    #check if the line isn't empty
    if [[ -n "$ip" ]]; then
        #add IP to ipset
        if sudo ipset add blacklist "$ip" 2>/dev/null; then
            echo -e "${GREEN}Blocked IP: ${ip}${NC}"
        else
            echo -e "${RED}IP ${ip} already exists in the blacklist or is invalid.${NC}"
        fi
    fi
done < "$file_path"

#all lines are done
echo -e "${YELLOW}All IP addresses have been processed.${NC}"
