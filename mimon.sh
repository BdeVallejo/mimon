#!/bin/bash

#Colours

green="\e[0;32m\033[1m"
end="\033[0m\e[0m"
red="\e[0;31m\033[1m"
yellow="\e[0;33m\033[1m"

trap ctrl_c INT

function ctrl_c(){
	echo -e "\n${green}[!] You're leaving, goodbye...${end}"
		tput cnorm; 
		ifconfig -a | grep "${networkCard}mon" > /dev/null 2>&1
		if [ "$(echo $?)" == "0" ]; then
	          airmon-ng stop ${networkCard}mon > /dev/null 2>&1
		  ifconfig ${networkCard} up > /dev/null 2>&1
		fi; sleep 1
	exit 0
}

function helpPanel() {
	echo -e "\n${yellow}[-] Help Panel${end}"
	echo -e "\t${yellow}n) Scans for trusted devices and then starts monitoring for devices joining your Wifi.${end}"
	echo -e "\t\t${yellow}You need to specify your network card (for instance wlan0}${end}"
	echo -e "\t${yellow}h) Help panel${end}\n"
	exit 0
}

# Checks if required tools are installed and installs them if not.

function tools() {
	tput civis
	clear; tools=(aircrack-ng macchanger)

	echo -e "${yellow}[-] Checking if all the stuff needed is installed...${end}"
	sleep 3

	for tool in "${tools[@]}"; do
		echo -ne "\n${yellow}[-] Tool: $tool ${end}"
		which $tool > /dev/null 2>&1
		if [ "$(echo $?)" == "0" ]; then
			echo -e "${green} (Installed)${end}"
		else
			echo -e "${red}[!] Needs to be installed before running this tool${end}\n"
			echo -e "\n\t${yellow}[+] Installing $tool...${end}"
			apt-get install $tool -y > /dev/null 2>&1
		fi; sleep 1
	done
}

function trustedMacs() {
	echo -e "\n${yellow}Setting your network card...${end}"
	airmon-ng start $networkCard > /dev/null 2>&1
	airmon-ng check kill > /dev/null 2>&1
	ifconfig ${networkCard}mon down > /dev/null 2>&1

	# This changes your MAC to a random MAC. You can see a list of MAC addresses with macchanger -l
	macchanger -a ${networkCard}mon > /dev/null 2>&1
	echo -e "\n${yellow}[-] $(macchanger -s ${networkCard}mon)${end}"
	ifconfig ${networkCard}mon up > /dev/null 2>&1
	echo -ne "\n${green}[+] Please, enter the essid of your WIFI (i.e MIWIFI_123):${end}" && read essid
	ssid=$(airodump-ng ${networkCard}mon --essid $essid | grep -m 1 "${essid}" | cut -d ' ' -f2)
	echo -e "\n${yellow} [-] Starting scan... This process will take 30 seconds${end}\n"
	timeout 30 bash -c "while true; do airodump-ng --essid $essid --bssid $ssid --write trustedDevices --output-format csv ${networkCard}mon; sleep 2; done" > /dev/null 2>&1
	cat trustedDevices-01.csv | tail -n +6 | sed 's/\|/ /' | awk '{print $1}' | tr ',' '\n' > trusted_ssids.txt
	rm -r trustedDevices-01.csv
	echo -e "\n${green} [!] Scan finished successfully!${end}\n"

}

function monitor() {
	echo -ne "\n${green}[+] Do you want to start monitoring for new devices joining your Wifi? (Y/N)...${end}" && read mon
	if [ $mon == "Y" ]; then
		echo  -e "\n${yellow}[-] Monitoring... Press Ctl + C to finish this proccess...${end}"
		while true; do
			timeout 15 bash -c "while true; do airodump-ng --essid $essid --bssid $ssid --write newDevices --output-format csv ${networkCard}mon; sleep 2; done" > /dev/null 2>&1
			cat newDevices-01.csv | tail -n +6 | sed 's/\|/ /' | awk '{print $1}' | tr ',' '\n' > new_ssids.txt
			rm -r newDevices-01.csv
			diff -w trusted_ssids.txt new_ssids.txt > /dev/null 2>&1
			if [ "$(echo $?)" == 1 ]; then
				echo -e "\n\t${green}[+] New Device Found! Someone has just joined your Wifi${end}"
			else
				echo -e "\n\t${red}[-] No devices found yet. Keeping our scan...${end}"
			fi; sleep 1
		sleep 2
		done
	else
		echo -e "${red}[!] Quitting..{end}"
	fi; sleep 1
	exit 0

}

# Main Function:

if [ "$(id -u)" == "0" ]; then
	declare -i parameter_counter=0; while getopts ":n:h:" arg; do
		case $arg in
			n) networkCard=$OPTARG; let parameter_counter+=1;;
			h) helpPanel;;
		esac
	done

	if [ $parameter_counter -ne 1 ]; then
		helpPanel
		tput cnorm
	else
		tools
		trustedMacs
		monitor
		tput cnorm; airmon-ng stop ${networkCard}mon > /dev/null 2>&1
		ifconfig ${networkCard} up > /dev/null 2>&1
	fi
else
	echo -e "\n${red}[!] You need to be root${end}\n"
fi
