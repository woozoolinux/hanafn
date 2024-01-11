#!/bin/bash

# This is System check script and available in RHEL7, RHEL8, RHEL9 version.
# Written by Linux Data System for Hana Financial Group.
# FileName: LDS_check.sh
# Versoin : 0.1.1v
# Date: 2024.01

# Language SET
LANG=C

# Vairable SET
DATE=$(date +%Y%m%d)
HOSTNAME=$(hostname)

# Directory SET
LDS_HOME=/home/LDS
REPORT_FILE="${LDS_HOME}/OS_Monthly_Report_${HOSTNAME}_${DATE}"

# Version Check
OS_VERSION=`cat /etc/redhat-release | grep -v ^# | awk '{print $(NF-1)}' | cut -d. -f1`

# check MAIN PATH
if [ ! -d  "$LDS_HOME" ]; then
        mkdir -p $LDS_HOME
fi

Hostname()
{
echo "=== HostName Check ==="
echo

cur_hostname=$(hostname)
echo "hostname = ${cur_hostname}"

echo
echo "===  End HostName ==="
echo
}

OsVersion()
{
echo "=== OsVersion Check ==="
echo

cat /etc/redhat-release

echo
echo "=== End OsVersion ==="
echo
}

FileSystem()
{
echo
echo "=== FileSystem Check ==="
echo 

echo "1. df -h result:"
df -h | grep -v tmpfs
echo

echo "2. df -i result:"
df -i | grep -v tmpfs
echo

echo "=== End FileSystem ==="
}

LogMessage()
{
echo
echo "=== LogMessage Check ==="
echo

LOG_CHECK=$(cat /var/log/messages* | egrep "^$(date -d '1 months ago' +%h)|^$(date +%h)" | egrep -iw '(I/O error|rejecting I/O to offline device|killing request|hostbyte=DID_NO_CONNECT|mark as failed|remaining active paths|parity|Abort command issued|Hardware Error|SYN flooding|fail|error|fault|down|WARN|Call Trace|reboo)'| egrep -i -v '(warn=True|auth|segfault|cdrom)'| egrep -i -v '(auth|segfault|cdrom|fd0|sr0|vxvm)'| egrep -v 'VCS' | egrep -v 'ACPI Error:\ SMBus|ACPI Error:\ Method parse|dockerd-current|Shutting Down Daemons|Shutting down..' | wc -l)

  if [ "$LOG_CHECK" -eq 0 ]; then
   echo "LOG Status: OK"
  else
   echo "LOG Status: BAD"
  fi
echo

cat /var/log/messages* | egrep "^$(date -d '1 months ago' +%h)|^$(date +%h)" | egrep -iw '(I/O error|rejecting I/O to offline device|killing request|hostbyte=DID_NO_CONNECT|mark as failed|remaining active paths|parity|Abort command issued|Hardware Error|SYN flooding|fail|error|fault|down|WARN|Call Trace|reboo)'| egrep -i -v '(warn=True|auth|segfault|cdrom)'| egrep -i -v '(auth|segfault|cdrom|fd0|sr0|vxvm)'| egrep -v 'VCS' | egrep -v 'ACPI Error:\ SMBus|ACPI Error:\ Method parse|dockerd-current|Shutting Down Daemons|Shutting down..'
echo
echo "=== End LogMessage ==="

}



main()
{
Hostname
OsVersion
FileSystem


LogMessage
}

main
