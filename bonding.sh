#!/bin/bash

## Check Interface
echo "=== Cureent Device Status ==="
nmcli device status

# Variable SET
master=bond0
slave1=enp1s0
slave2=enp7s0
bond_mode=active-backup

ip_addr=192.168.155.95/24
gateway=192.168.155.1
dns=8.8.8.8


# Prompt user with warning message
read -p "${slave1}, ${slave2} interfaces will be used to create ${master} device. Is this correct? (y/n): " userInput

# Check if input is 'y'
if [ "$userInput" == "y" ]; then
	echo "Configuring bonding..."
	## set bond device
	nmcli connection add type bond con-name ${master} ifname ${master} bond.options "mode=${bond_mode},miimon=100"
                ## set bond slave device
		for i in ${slave1} ${slave2}
		do
			
			if [ $(nmcli con show | grep ${i} | grep ethernet | wc -l) -eq 0 ];
			then
			echo "${i} making..."
			nmcli connection add type ethernet slave-type bond con-name ${i} ifname ${i} master ${master}
			else
			echo "${i} delete and making..."
			#nmcli connection modify ${i} master ${master}
			cur_con=$(nmcli -t -f NAME,DEVICE con show| grep $i | cut -d: -f1)
			nmcli connection delete "${cur_con}"
			nmcli connection add type ethernet slave-type bond con-name ${i} ifname ${i} master ${master}
			fi
		done
	## set bond IP address	
	nmcli connection modify ${master} ipv4.addresses ${ip_addr} ipv4.gateway ${gateway} ipv4.dns ${dns} ipv4.method manual autoconnect on
	nmcli connection up ${slave1}
	nmcli connection up ${slave2}
	nmcli connection modify ${master} connection.autoconnect-slaves 1
	nmcli connection up ${master}

else
    echo "Exiting the process."
fi


