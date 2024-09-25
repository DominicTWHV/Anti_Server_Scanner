#!/bin/bash

#colorful echo again!
RED='\033[0;31m'    #red
GREEN='\033[0;32m'  #green
YELLOW='\033[0;33m' #yellow
BLUE='\033[0;34m'   #blue
NC='\033[0m'        #no color

#ask for file path
echo -e "${BLUE}Please enter the file path containing IP addresses:${NC}"
read -r file_path

#check if exists
if [[ ! -f "$file_path" ]]; then
    echo -e "${RED}Error: File does not exist.${NC}"
    exit 1
fi

#read line by line
while IFS= read -r ip; do
    #check line isnt empty
    if [[ -n "$ip" ]]; then
        #add entry to iptables
        sudo iptables -A INPUT -s "$ip" -j DROP
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}Blocked IP: ${ip}${NC}"
        else
            echo -e "${RED}Failed to block IP: ${ip}${NC}"
        fi
    fi
done < "$file_path"

#all lines are done
echo -e "${YELLOW}All IP addresses have been processed.${NC}"
