#!/bin/bash

#colorful echo!
RED='\033[0;31m'    #red
GREEN='\033[0;32m'  #green
YELLOW='\033[0;33m' #yellow
BLUE='\033[0;34m'   #blue
NC='\033[0m'        #  color

#check if sudo
if [[ "$EUID" -ne 0 ]]; then
    echo -e "${RED}Please run this script as root or with sudo.${NC}"
    exit 1
fi

#input file path
echo -e "${BLUE}Please enter the file path containing IP addresses, if you are using my other repo (MCIPBlocklist), enter 'set.txt' here.${NC}"
read -r file_path

#validate path
if [[ -z "$file_path" ]]; then
    echo -e "${RED}Error: No file path provided.${NC}"
    exit 1
fi

#check if exists
if [[ ! -f "$file_path" ]]; then
    echo -e "${RED}Error: File does not exist.${NC}"
    exit 1
fi

#make ipset if doesnt exist
if ! ipset list blacklist &>/dev/null; then
    sudo ipset create blacklist hash:ip || {
        echo -e "${RED}Failed to create ipset 'blacklist'. Exiting.${NC}"
        exit 1
    }
    echo -e "${YELLOW}Created ipset 'blacklist'.${NC}"
fi

#make iptables rule if doesnt exist
if ! sudo iptables -C INPUT -m set --match-set blacklist src -j DROP &>/dev/null; then
    sudo iptables -I INPUT -m set --match-set blacklist src -j DROP || {
        echo -e "${RED}Failed to add iptables rule. Exiting.${NC}"
        exit 1
    }
    echo -e "${YELLOW}Added iptables rule to drop packets from 'blacklist'.${NC}"
fi

#success counters/error counter
success_count=0
error_count=0

#read ip line by line
while IFS= read -r ip; do
    #check line isnt empty
    if [[ -n "$ip" ]]; then
        #validate ip
        if [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
            #check ip is already blocked or not
            if ! sudo ipset test blacklist "$ip" &>/dev/null; then
                #add to ipset if not
                if sudo ipset add blacklist "$ip" 2>/dev/null; then
                    echo -e "${GREEN}Blocked IP: ${ip}${NC}"
                    ((success_count++))
                else
                    echo -e "${RED}Failed to add IP: ${ip}${NC}"
                    ((error_count++))
                fi
            else
                echo -e "${YELLOW}IP ${ip} is already in the blacklist.${NC}"
            fi
        else
            echo -e "${RED}Invalid IP format: ${ip}${NC}"
            ((error_count++))
        fi
    fi
done < "$file_path"

# Check if the iptables rule already exists, add it if it doesn't
if ! sudo iptables-save | grep -q "match-set blacklist src"; then
    sudo iptables -I INPUT -m set --match-set "blacklist" src -j DROP
    echo -e "${GREEN}Creating iptables rule because it doesn't exist.${NC}"
fi

#make sure rules will persist even after reboot
sudo ipset save > /etc/ipset.rules
sudo netfilter-persistent save
sudo netfilter-persistent reload

#echo final
echo -e "${YELLOW}Processed ${success_count} IPs successfully. ${error_count} errors occurred.${NC}"
