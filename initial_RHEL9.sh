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

## SET NTP ADDRESS
## ex) NTP_Address="123.123.123.1 123.123.123.2"
NTP_Address="111.15.30.23"

## Enter the package name you want to install
## ex) Package_list="net-tools sysstat"
Package_list="net-tools sysfsutils pciutils sysstat traceroute createrepo sos lvm2 java-1.8.0-openjdk-devel"



NTP()
{

# Diable default chrony pool
sed -i  "/^pool/s/pool/#pool/" /etc/chrony.conf

# Set time server if NTP_Adress configured
if [ -z ${NTP_Address} ];
then
        echo "NTP WARNING!!"
        echo "NO NTP ADDRESS, PLEASE SET NTP VARIABLE!!"
else
        for i in $NTP_Address
        do
        	echo "server ${i} iburst" >> /etc/chrony.conf
        done

        # start and enable chronyd service
        systemctl restart chronyd
        systemctl enable chronyd
	echo "chronyd service configured"
fi



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

