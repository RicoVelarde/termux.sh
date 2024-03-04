#!/bin/bash

clear

# Function to end script on signal
endscript() {
  exit 1
}

trap endscript SIGINT SIGTERM

# Download domain and IP files
wget -q -O domains.txt https://raw.githubusercontent.com/JKimDevs/termux/main/domains.txt
wget -q -O ip.txt https://raw.githubusercontent.com/JKimDevs/termux/main/ip.txt

# Read DNS IPs and NameServers
IFS=$'\r\n' GLOBIGNORE='*' command eval 'DNS_IPS=($(cat ip.txt))'
IFS=$'\r\n' GLOBIGNORE='*' command eval 'NAME_SERVERS=($(cat domains.txt))'

# Initial loop delay
LOOP_DELAY=2
echo -e "\e[1;37mCurrent loop delay is \e[1;33m${LOOP_DELAY}\e[1;37m seconds.\e[0m"
echo -e "\e[1;37mWould you like to change the loop delay? \e[1;36m[y/n]:\e[0m "
read -r change_delay

# Update loop delay based on user input
if [[ "$change_delay" == "y" ]]; then
  echo -e "\e[1;37mEnter custom loop delay in seconds \e[1;33m(5-15):\e[0m "
  read -r custom_delay
  if [[ "$custom_delay" =~ ^[5-9]$|^1[0-5]$ ]]; then
    LOOP_DELAY=$custom_delay
  else
    echo -e "\e[1;31mInvalid input. Using default loop delay of ${LOOP_DELAY} seconds.\e[0m"
  fi
fi

# Determine dig command
DIG_EXEC="DEFAULT"
CUSTOM_DIG=/data/data/com.termux/files/home/go/bin/fastdig

case "${DIG_EXEC}" in
  DEFAULT|D)
    _DIG="$(command -v dig)"
    ;;
  CUSTOM|C)
    _DIG="${CUSTOM_DIG}"
    ;;
esac

# Check for dig command availability
if [ ! $(command -v ${_DIG}) ]; then
  printf "%b" "Dig command not available, please install dnsutils or adjust DIG_EXEC & CUSTOM_DIG variables.\n" && exit 1
fi

# Initialize counter
count=1

# Function to perform checks
check() {
  local border_color="\e[95m"
  local success_color="\e[92m"
  local fail_color="\e[91m"
  local header_color="\e[96m"
  local reset_color="\e[0m"
  local padding="  "

  echo -e "${border_color}┌────────────────────────────────────────────────┐${reset_color}"
  echo -e "${border_color}│${header_color}${padding}DNS Status Check Results${padding}${reset_color}"
  echo -e "${border_color}├────────────────────────────────────────────────┤${reset_color}"
  
  for T in "${DNS_IPS[@]}"; do
    for R in "${NAME_SERVERS[@]}"; do
      result=$(${_DIG} @${T} ${R} +short)
      STATUS="${fail_color}Failed${reset_color}"
      [ -n "$result" ] && STATUS="${success_color}Success${reset_color}"
      
      echo -e "${border_color}│${padding}${reset_color}DNS IP: ${T}${reset_color}"
      echo -e "${border_color}│${padding}NameServer: ${R}${reset_color}"
      echo -e "${border_color}│${padding}Status: ${STATUS}${reset_color}"
    done
  done

  echo -e "${border_color}├────────────────────────────────────────────────┤${reset_color}"
  echo -e "${border_color}│${padding}${header_color}Check count: ${count}${padding}${reset_color}"
  echo -e "${border_color}│${padding}Loop Delay: ${LOOP_DELAY} seconds${padding}${reset_color}"
  echo -e "${border_color}└────────────────────────────────────────────────┘${reset_color}"
}

# Countdown before starting checks
countdown() {
    for i in $(seq $LOOP_DELAY -1 1); do
        echo "Checking started in $i seconds..."
        sleep 1
    done
}

# Main execution
countdown
clear
while true; do
  check
  ((count++))
  sleep $LOOP_DELAY
done

exit 0
