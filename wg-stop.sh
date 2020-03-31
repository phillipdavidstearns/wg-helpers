#!/bin/bash

function usage {
	echo -e "\nUsage: wg-stop.sh -i iface_name"
	echo -e "\t-i\t\ttunnel interface name (e.g. utun0)"
	echo -e "\n"
}

while getopts "i:h:" opt; do
	case $opt in
		i)
			if ifconfig $OPTARG >/dev/null 2>&1; then
				IFACE="$OPTARG"
			else
				echo "[!] Interface $OPTARG doesn't exists."
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

if [[ -z "$IFACE" ]]; then
	sudo rm /var/run/wireguard/* >/dev/null 2>&1
else
	sudo rm "/var/run/wireguard/$IFACE.sock"
fi

exit 0