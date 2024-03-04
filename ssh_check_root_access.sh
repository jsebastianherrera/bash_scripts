#!/bin/bash
green="\e[0;32m\033[1m"
end="\033[0m\e[0m"
red="\e[0;31m\033[1m"
blue="\e[0;34m\033[1m"
yellow="\e[0;33m\033[1m"
purple="\e[0;35m\033[1m"
turquoise="\e[0;36m\033[1m"

function logo() {
	echo -e "${purple}"
	echo -e "\t ____  ____  _    _  ___  ___  "
	echo -e "\t(  _ \( ___)( \/\/ )/ __)/ _ \ "
	echo -e "\t )___/ )__)  )    (( (__( (_) )"
	echo -e "\t(__)  (____)(__/\__)\___)\___/ "
	echo
	sleep 1
	echo -e " [I] This script have been made only for educational purposes"
	sleep 1
	echo -e " [I] Use it under your resposibility."
	echo -e "${end}"
}

function usage() {
	echo "Usage: $0 -i <input_file>"
	exit 1
}

function cleanup() {
	echo -e "${red}Killing process${end}"
	exit 1
}
function check_packages() {
	local missing=()
	packages=("curl" "sshpass" "ssh" "proxychains")
	for p in ${packages[@]}; do
		if ! command -v $p &>/dev/null; then
			missing+=($p)
		fi
	done
	length=${#missing[@]}
	if [[ $length -gt 0 ]]; then
		echo -e "${red}$length packages(s) need to be installed!${end}"
		echo "Installing missing packages..."
		for p in ${length[@]}; do
			sudo apt install -y $p &>/dev/null
			if [ $? -eq 0 ]; then
				echo -e "${green}[OK] $p ${end}"
			else
				echo -e "${red}[OK] $p ${end}"
			fi
		done
	fi
}
function proxy_check {
	current=$(curl --silent "https://api.ipify.org?format=json" | grep -oP "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}")
	proxychain=$(proxychains curl --silent "https://api.ipify.org?format=json" 2>/dev/null | grep -oP "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}")
	if [[ $? -ne 0 || "${current}" == "${proxychain}" ]]; then
		echo -e "${red}Your connection is not being routed...${end}"
		exit 1
	else
		echo -e "${green}[OK] Your connection is being routed...${end}"
		echo -e "Original IP: ${red}${current}${end}"
		echo -e "Routed IP: ${green}${proxychain}${end}"
	fi

}
function test_ssh() {
	echo -n "Trying with $1..."
	proxychains sshpass -p root ssh root@$1 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null exit &>/dev/null
	if [[ $? -eq 0 ]]; then
		echo -e "${green} [V]${end}"
	else
		echo -e "${red} [X] ${end}"
	fi
}

# MAIN
trap cleanup SIGINT
logo
check_packages
while getopts "i:" opt; do
	case $opt in
	i)
		proxy_check
		file="$OPTARG"
		if [ -f "$file" ]; then
			while IFS= read -r line; do
				test_ssh $line
			done <"$file"
		else
			echo -e "${red}File not found ${file} ${end}"
		fi
		;;
	\?)
		usage
		;;
	esac
done
