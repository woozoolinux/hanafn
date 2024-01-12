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
NTP_Address=111.15.30.23 

NTP()
{
sed -i "/^pool/s/.*/server 111.15.30.23/" /etc/chrony.conf
systemctl restart chronyd
systemctl enable chornyd
}

install net-tools sysfsutils pciutils sysstat traceroute createrepo sos lvm2 java-1.8.0-openjdk-devel
