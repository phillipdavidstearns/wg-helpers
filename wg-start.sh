#!/bin/bash

#----------------------------------------------------------------

# how to use this thing
function usage {
	echo -e "\nUsage: wg-start.sh -i iface_name -a ip_address -c path_to_conf_file"
	echo -e "\t-h\t\tdisplay this help message"
	echo -e "\t-i\t\ttunnel interface name (e.g. utun0)"
	echo -e "\t-a\t\tip address (e.g. 10.0.0.1)"
	echo -e "\t-c\t\t/full/path/to/file.conf (e.g. /etc/wireguard/wg0.conf)"
	echo -e "\n"
}

#----------------------------------------------------------------
# This is where you can set some of 

WG_START_CONFIG_PATH="/etc/wireguard/wg-start.conf"

#----------------------------------------------------------------
# discover an unused utun interface name

function find_interface {
	local i=0
	while [[ "$( ifconfig utun$i >/dev/null 2>&1; echo $? )" == 0 ]];do
		((i++))
		if [[ "$i" -gt 20 ]]; then
			echo "[!] Unable to find available utun interface"
			return 1
		fi
	done
	IFACE="$(echo utun$i)"
	return 0
}

#----------------------------------------------------------------
# Read the config located at "/etc/wireguard/wg-start.conf" and set variables

# Default values if no config file exists AND no arguments are passed
function fetch_config {
    val=$( ( grep -E "^$1=" $WG_START_CONFIG_PATH 2>/dev/null || echo "$1=__DEFAULT__" ) | head -n 1 | cut -d '=' -f 2-)

    if [[ $val == __DEFAULT__ ]]
    then
        case $1 in
            IP_ADDR)
                echo -n "10.42.0.254"
                ;;
            CONF_PATH)
                echo -n "/etc/wireguard/wg0.conf"
                ;;
            IFACE)
				find_interface
                echo -n "$IFACE"
                ;;
        esac
    else
        echo -n $val
    fi
}

# read values from the config file
IP_ADDR=$(fetch_config IP_ADDR)
CONF_PATH=$(fetch_config CONF_PATH)
IFACE=$(fetch_config IFACE)

#----------------------------------------------------------------

# check whether an IP address is a valid one
function ip_is_valid {

	local  ip="$1"
	local  stat="1"
	if [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
		IFS='.'
		ip=($ip)
		unset IFS
		[[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
		stat="$?"
    fi
    return $stat
}

#----------------------------------------------------------------

# parse arguments & options
while getopts "i:a:c:h" opt; do
	case $opt in
		i)
			
			if ifconfig $OPTARG >/dev/null 2>&1; then
				echo "[!] Interface $OPTARG already in use."
				# exit 1
			else
				IFACE="$OPTARG"
			fi
		;;
		a)
			if ip_is_valid $OPTARG; then
				IP_ADDR="$OPTARG"
			else
				echo "[!] Supplied IP address is invalid"
				exit 1
			fi			
		;;
		c)
			if [[ -f "$OPTARG" ]]; then
				CONF_PATH="$OPTARG"
			else
				echo "[!] $OPTARG is not a regular file."
				exit 1
			fi
		;;
		h)
			usage
			exit 0
		;;
		*)
			#Printing error message
			echo "[!] invalid option or argument $OPTARG"
			exit 1
		;;
	esac
done

#----------------------------------------------------------------

# find the next available utun interface
if ! echo $IFACE | grep -E 'utun[0-9]{1,2}' >/dev/null 2>&1; then
	echo "[!] Invalid interface $IFACE."
	exit 1
elif ifconfig $IFACE >/dev/null 2>&1; then
	echo "[!] Interface $IFACE in use"
	if find_interface;then
		echo "[+] Using interface $IFACE"
	fi
else
	echo "[+] Using interface $IFACE"
fi

#----------------------------------------------------------------

if ! ip_is_valid $IP_ADDR; then
	echo "[!] Supplied IP address is invalid"
	exit 1
fi

NET="$(echo $IP_ADDR | cut -f 1-3 -d '.').0/24"

#----------------------------------------------------------------

if [[ ! -f "$CONF_PATH" ]]; then
	echo "[!] $CONF_PATH is not a regular file."
	exit 1
fi

#----------------------------------------------------------------

echo "[+] Starting wireguard iface using wireguard-go."

# create tunnel interface
if sudo wireguard-go $IFACE; then
	echo "[+] Started wireguard iface on $IFACE."
else
	echo "[!] Failed to start wireguard."
	exit 1
fi

#----------------------------------------------------------------

# configure wireguard tunnel interface
if sudo wg setconf $IFACE $CONF_PATH; then
	echo "[+] $IFACE successfully configured using $CONF_PATH"
else
	echo "[!] Failed to configure $IFACE using $CONF_PATH"
	sudo rm /var/run/wireguard/$IFACE.sock
	exit 1
fi

#----------------------------------------------------------------

# assign IP address with the tunnel interface
if sudo ifconfig $IFACE $IP_ADDR $IP_ADDR; then
	echo "[+] Added route $IP_ADDR > $IP_ADDR to $IFACE."
else
	echo "[!] Failed to add route $IP_ADDR > $IP_ADDR to $IFACE."
	sudo rm /var/run/wireguard/$IFACE.sock
	exit 1
fi

#----------------------------------------------------------------

# assign route to tunnel interface
if sudo route add -net $NET -interface $IFACE; then
	echo "[+] Added route to subnet $NET to $IFACE."
else
	echo "[+] Failed to add route to subnet $NET to $IFACE."
	sudo rm /var/run/wireguard/$IFACE.sock
	exit 1
fi

#----------------------------------------------------------------

sudo wg show

exit $?
