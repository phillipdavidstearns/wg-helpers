# OSX Wireguard Helper Scripts

scripts for setting up a wireguard interface on OSX when `wg-quick` fails

## Usage

```
Usage: wg-start.sh -i iface_name -a ip_address -c path_to_conf_file
	-h		display this help message
	-i		tunnel interface name (e.g. utun0)
	-a		ip address (e.g. 10.0.0.1)
	-c		/full/path/to/file.conf (e.g. /etc/wireguard/wg0.conf)
```

---

# Wireguard on OSX

## Install

* get homebrew from [brew.sh](https://brew.sh): `$ /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"`
* install the Command Line Tools: `$ xcode-select --install`
* install wireguard: `$ brew install wireguard-tools`

## Generate Keys

1. return to your home directory: `$ cd ~`
1. set permission mask to owner read/write/execute only: `$ umask 077`
1. create a hidden wireguard directory: `$ mkdir .wireguard`
1. enter the directory: `$ cd .wireguard`
1. gereate pubilc and private keys: `$ wg genkey | tee privatekey | wg pubkey > publickey`

## Create Configuration File

1. `$ sudo mkdir /etc/wireguard/`
1. `$ sudo nano /etc/wireguard/wg0.conf`

Enter:

```
[Interface]
PrivateKey = <client_pubilc_key>

[Peer]
Endpoint = <endpoint_ip_address:port>
PublicKey = <server_public_key>
AllowedIPs = <vpn_subnet>
PersistentKeepalive = 20
```

* replace: `<client_private_key>` with the contents of `~/.wireguard/privatekey`.
* replace: `<endpoint_ip_address:port>` with the ipaddress or domain name of the server and the server listening port. e.g.: `123.123.123.123:12345`
* replace: `<server_public_key>` with the server **public** key.
* replace: `<vpn_subnet` with the ip range of the subnet used by the vpn. e.g.: `123.123.123.0/24`

## Manually setting up an interface (OSX)

1. `$ sudo wireguard-go utun<number>` (replace <number> with any number 0-20)
1. `$ sudo wg setconf utun<number> </path/to/config/file>` (replace </path/to/config/file> with something like /etc/wireguard/wg0.conf)
1. `$ sudo ifconfig $IFACE $IP_ADDR $IP_ADDR` 

## Using `wg-quick` (OSX)

1. `$ wg-quick up /etc/wireguard/wg0.conf`

## Using custom scripts

### Install

Feel free to change directories to meet your file management needs.

1. Change to your home directory: `$ cd ~`
1. Clone the repo containing example scripts: `$ git clone https://github.com/phillipdavidstearns/wg-helpers.git`
1. Change permissions of `wg-sart.sh`: `$ sudo chmod +x ~/wg-helpers/wg-start.sh`
1. Create a symbolic link to `wg-start.sh`: `$ sudo ln -s /Users/$USER/wg-helpers/wg-start.sh /usr/local/bin/wg-start`
1. Change permissions of `wg-stop.sh`: `$ sudo chmod +x ~/wg-helpers/wg-stop.sh`
1. Create a symbolic link to `wg-stop.sh`:`$ sudo ln -s /Users/$USER/wg-helpers/wg-stop.sh /usr/local/bin/wg-stop`

### Setup

1. Create a config file for `wg-start`: `$ sudo nano /etc/wireguard/wg-start.conf`

Enter:

```
IP_ADDR=<your_vpn_ip>
CONF_PATH=</path/to/your/wg.conf>
IFACE=<utun_device>
```

* replace: `<your_vpn_ip>` with the ip address configured on your vpn server for your device. e.g.: `123.123.123.123`
* replace: `</path/to/your/wg.conf>` with the path to your wireguard configuration file. e.g.: `/etc/wireguard/wg0.conf`
* replace: `<utun_device>` with the tunnel interface name you wish to use by default. e.g: `utun2`

### Start up the wireguard interface:

1. `$ sudo wg-start`

