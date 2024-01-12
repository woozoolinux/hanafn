#!/bin/bash

##WARNING##
#"Run this script only on newly installed servers."#

# This is System initial script.
# Written by Linux Data System for Hana Financial Group.
# FileName: LDS_initial_RHEL9.sh
# Versoin : 0.1.1v
# Date: 2024.01

# Language SET
LANG=C

# Version Check
OS_VERSION=`cat /etc/redhat-release | grep -v ^# | awk '{print $(NF-1)}' | cut -d. -f1`


# Variable SET
NTP_Address="111.15.30.23 11.22.33.44" 
Package_list="net-tools sysfsutils pciutils sysstat traceroute createrepo sos lvm2 java-1.8.0-openjdk-devel"

NTP()
{

# Diable default chrony pool
sed -i  "/^pool/s/pool/#pool/" /etc/chrony.conf

# Insert time server
for i in $NTP_Address
do
	echo "server ${i} iburst" >> /etc/chrony.conf
done

# start and enable chronyd service
systemctl restart chronyd
systemctl enable chronyd

echo "chronyd service configured"
}

LocalRepo()
{
echo
}

PackageInstall()
{
dnf install -y ${Package_list}
}


NTP
#PackageInstall

