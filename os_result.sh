#!/bin/bash

# This is a script for retrieving OS information.
# Written by Linux Data System for Hana Financial Group.
# FileName: os_result.sh
# Versoin : 0.1.1v
# Date: 2024.01

# Language SET
LANG=C

function server_list()
{
for i in $(ls /home/hana/sosreport)
do
echo $i
done
}

function server_info()
{

echo "print server list"
result=`server_list`
for i in $result
do
	echo -n "$(cat sosreport/$i/hostname) "
done
echo
echo


result=`server_list`
for i in $result
do
cur_hostname=$(cat sosreport/$i/hostname)
cur_release=$(cat sosreport/$i/etc/redhat-release)
firewall_state=$(cat sosreport/$i/sos_commands/systemd/systemctl_list-unit-files | grep firewall | awk '{print $1": "$2}')
selinux_state=$(cat sosreport/$i/sos_commands/selinux/sestatus | awk '{print $1 $2" "$3}')
kdump_state=$(cat sosreport/$i/sos_commands/systemd/systemctl_list-unit-files | grep kdump | awk '{print $1": "$2}')


echo "${cur_hostname}"
echo "${cur_release}"
echo "${firewall_state}"
echo "${selinux_state}"
echo "${kdump_state}"
echo

done
}


function hw_info()
{
echo

result=`server_list`
for i in $result
do
	cur_hostname=$(cat sosreport/$i/hostname)
	product_name=$(cat sosreport/$i/dmidecode | grep "System Information" -A5 | grep "Product Name")
	cpu_info=$(cat sosreport/$i/proc/cpuinfo  | grep "model name" | uniq | cut -d: -f2)
	core_num=$(cat sosreport/$i/sos_commands/processor/lscpu | grep ^CPU\(s\):| awk '{print $1" "$2}')
	mem_info=$(cat sosreport/$i/sos_commands/memory/lsmem_-a* | grep "Total online memory:"| awk '{print "Mem: "$NF}')

	echo "${cur_hostname}"
	echo "Model: ${product_name}"
	echo "CPU: ${cpu_info} / ${core_num}" 
	echo "${mem_info}"


	echo

done
}

function disk_info()
{
echo

result=`server_list`
for i in $result
do
	cur_hostname=$(cat sosreport/$i/hostname)
	disk_list=$(cat sosreport/$i/sos_commands/block/lsblk | grep disk)

	echo "${cur_hostname}"
	echo "${disk_list}:"
	echo

done
}


server_info
hw_info
disk_info
