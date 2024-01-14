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

## SET LOCAL REPO
repo_source_dir="/iso"
repo_file="/etc/yum.repos.d/local.repo"

## Enter the package name you want to install
## ex) Package_list="net-tools sysstat"
Package_list="net-tools sysfsutils pciutils sysstat traceroute createrepo sos lvm2 java-1.8.0-openjdk-devel"


# Prompt user with warning message
read -p "Did you finish copying the packages to the ${repo_source_dir} directory? (y/n): " userInput

# Check if input is 'y'
if [ "$userInput" == "y" ]; then
        continue
else
        exit 1
fi



NTP()
{
echo "=== NTP SET ==="
# Executed only when the NTP_Address variable is set.
if [ -z ${NTP_Address} ];
then
        echo "NTP WARNING!!"
        echo "NO NTP ADDRESS, PLEASE SET NTP VARIABLE!!"
else
        # Diable default chrony pool
        sed -i  "/^pool/s/pool/#pool/" /etc/chrony.conf

        # Set time server if NTP_Adress configured
        for i in $NTP_Address
        do
        	echo "server ${i} iburst" >> /etc/chrony.conf
        done

        # start and enable chronyd service
        systemctl restart chronyd
        systemctl enable chronyd
	echo "chronyd service configured"
fi
echo "=== NTP FINISH ==="
}

LocalRepo()
{
echo "=== Yum Repository SET ==="
repo_text=$(cat <<EOF
[BaseOS]
name=BaseOS
baseurl=file:${repo_source_dir}/BaseOS
gpgcheck=0
enabled=1
[AppStream]
name=AppStream
baseurl=file:${repo_source_dir}/AppStream
gpgcheck=0
enabled=1
EOF
)

echo "$repo_text" > $repo_file

echo "=== Yum Repository FINISH ==="
}

PackageInstall()
{
echo "=== Package install ==="
if [ -z ${Package_list} ];
then
        echo "NO Package install"
else
	dnf install -y ${Package_list}
fi
echo "=== Package Install FINISH ==="
}


NTP
LocalRepo
PackageInstall

