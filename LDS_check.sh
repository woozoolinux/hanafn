#!/bin/bash

# This is System check script and available in RHEL6, RHEL7, RHEL8, RHEL9 version.
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

Hostname(){
echo "=== HostName Check ==="
echo

cur_hostname=$(hostname)
echo "hostname = ${cur_hostname}"

echo
echo "===  End HostName ==="
echo
}

OsVersion(){
echo "=== OsVersion Check ==="
echo

cat /etc/redhat-release

echo
echo "=== End OsVersion ==="
echo
}

FileSystem(){
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

LogMessage(){
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

UserInfo(){
echo
echo "=== UserInfo Check ==="
echo

cur_userc=$(cat /etc/passwd | wc -l)
cur_groupc=$(cat /etc/group | wc -l)

echo "user_count = ${cur_userc}"
echo "group_count = ${cur_groupc}"
echo
echo "=== End UserInfo ==="
echo
}

NetworkPacket(){
echo
echo "=== NetworkPacket Check ==="
echo

for i in $(ls /sys/class/net/ | egrep -v "vnet|lo|macv")
 do
 ifconfig $i
 done

echo
echo "=== End NetworkPacket ==="
echo
}

NetworkRoute(){
echo
echo "=== NetworkRoute Check ==="
echo 

route -n
echo 
echo "=== End NetworkRoute ==="
echo
}

BondingInfo(){
echo
echo "=== BondingInfo Check ==="
echo 

bonFlag=0
mbond=`lsmod | grep bond`
if [ -z "$mbond" ];then
	echo ""
	echo "Bonding Status: WARNING"
   	echo "bond check result: bonding module not loading"
else
	bondlist=`ls /proc/net/bonding/*`
	for i in $bondlist; do
		echo "=${bondlist} Bonding Status="
		cat $i
		bondNum=`cat $i | egrep -A1 "Slave Interface"  | grep up| wc -l`
		if [ "$bondNum" == 2 ]; then
			continue			
		else
			bonInterface=`ls $bondlist | awk -F"/" '{print $NF}'`
			echo ""
			echo ""
			echo "Bonding Status: WARNING"
        		echo "Check $bonInterface status!!"
			echo ""
			bonFlag=3
		fi
	done

if [ "$bonFlag" == 0 ]; then
	echo ""
	echo "Result"
	echo "Bonding Status: OK"
fi

fi

echo 
echo "=== End BondingInfo ==="
echo
}

ZombieProcess(){
echo
echo "=== ZombieProcess Check ==="
echo 

zombie=`ps aux | awk ' $8=="Z" || $8=="Z+" {print $0}' | wc -l`
cur_zombie=`ps aux | awk ' $8=="Z" || $8=="Z+" {print $0}'`

 if [ "$zombie" -gt 0 ]; then
  echo "Zombie Process: $zombie "
  echo ""
  echo "Current zombie process status:"
  ps aux | head -1
  echo "$cur_zombie"
 else
  echo "No Zombie Process"
  echo "Result: OK"
 fi

echo 
echo "=== End ZombieProcess ==="
echo
}

Uptime(){
echo
echo "=== Uptime Check ==="
echo 

cur_uptime=`uptime | grep -w days`
cur_uptime_min=`uptime | awk '{print $3}' | cut -d, -f 1`

if [ -n "$cur_uptime" ]; 
  then 
  	days=`echo $cur_uptime | awk '{print $3}'`	
 	if [ "$days" -ge 365 ]; then
   	echo "UPTIME: $days days"
  	else
   	echo "SYSTEM UPTIME: OK"
   	echo "UPTIME: $days days"
  	fi
  else
  echo -e "SYSTEM UPTIME: OK"	
  echo "UPTIME: $cur_uptime_min min"
fi

echo 
echo "=== End Uptime ==="
echo
}

NtpInfo(){
echo
echo "=== NtpInfo Check ==="
echo 
if [ ${OS_VERSION} -le 6 ];
then
        service ntpd status &> /dev/null
        rhel6_ntp="$?"
        if [ "$rhel6_ntp" = 0 ]
        then
                cur_runlevel=$(cat /etc/inittab | grep -v ^# | grep ^id | cut -d: -f 2)
                cur_enabled=$(chkconfig --list | grep -w ntpd | cut -d${cur_runlevel} -f 2 | awk '{print $1}' | cut -d: -f2)

                if [ ${cur_enabled} == on ]
                then
                        echo "RESULT: OK"
                        echo
                        service ntpd status
                        echo "Current Time:"
                        ntpq -p
                else
                        echo "RESULT: WARNING"
                        echo "NTPD DAEMON STARTED BUT NOT ENABLED"
			echo
                        service ntpd status
                        echo "Current Time:"
			ntpq -p
                fi
        else
                echo "RESULT: WARNING"
                echo "NTPD NOT RUNNING"
        fi
fi



if [ ${OS_VERSION} -eq 7 ];
then
        systemctl status ntpd &> /dev/null
    	rhel7_ntp=$?
        systemctl status chronyd &> /dev/null
      	rhel7_chronyd=$?
        if [ ${rhel7_ntp} -eq 0 ]
       	then
		cur_ntp_enable=$(systemctl is-enabled ntpd)
		if [ ${cur_ntp_enable} == enabled ]
		then
    			echo "RESULT: OK"
			echo
			systemctl status ntpd
			echo
			ntpq -p
		else
			echo "RESULT: WARNING"
                        echo "NTPD DAEMON STARTED BUT NOT ENABLED"
			service ntpd status
                        echo "Current Time:"
                        ntpq -p
		fi
    	elif [ ${rhel7_chronyd} -eq 0 ]
	then
		cur_chrony_enable=$(systemctl is-enabled chronyd)
		if [ ${cur_chrony_enable} == enabled ]
		then
    			echo "RESULT: OK"
			echo
			systemctl status chronyd
			echo
			chronyc sources
		else
			echo "RESULT: WARNING"
                        echo "CHRONYD DAEMON STARTED BUT NOT ENABLED"
			echo
                        systemctl status chronyd
                        echo
                        chronyc sources

		fi
    	else
		echo "RESULT: WARNING"	
		echo "NTPD DAEMON NOT STARTED"
    	fi
fi

if [ ${OS_VERSION} -ge 8 ];
then
        systemctl status chronyd &> /dev/null
        rhel8_chronyd=$?
        if [ ${rhel8_chronyd} -eq 0 ]
	then
		cur_chrony8_enable=$(systemctl is-enabled chronyd)
                if [ ${cur_chrony8_enable} == enabled ]
                then
                	echo "RESULT: OK"
			echo
                	systemctl status chronyd 2> /dev/null
			echo
			chronyc sources
		else
			echo "RESULT: WARNING"
                        echo "CHRONYD DAEMON STARTED BUT NOT ENABLED"
			systemctl status chronyd 2> /dev/null
                        echo
                        chronyc sources
		fi
        else
                echo "RESULT: WARNING"
                echo "NTPD DAEMON NOT STARTED"
        fi

fi

echo 
echo "=== End NtpInfo ==="
echo
}

Kdump(){
echo
echo "=== Kdump Check ==="
echo


cat /proc/cmdline | grep crash &> /dev/null
cmdline=$?

if [  ${cmdline} -ne 0 ]
then
	echo "RESULT: WARNING"
	echo "kdump memory not set"
	return
fi

if [ ${OS_VERSION} == 6 ] ## FOR RHEL6
then
	service kdump status $> /dev/null
	rhel6_dump_state=$?
	if [ ${rhel6_dump_state} -eq 0 ]
	then
		cur_runlevel=$(cat /etc/inittab | grep -v ^# | grep ^id | cut -d: -f 2)
                cur_enabled=$(chkconfig --list | grep -w kdump | cut -d${cur_runlevel} -f 2 | awk '{print $1}' | cut -d: -f2)
		
		if [ ${cur_enabled} == on ]
                then
                        echo "RESULT: OK"
                        echo
			service kdump status
			echo 
		else
			echo "RESULT: WARNING"
                        echo "KDUMP DAEMON STARTED BUT NOT ENABLED"
                        service kdmup status
		fi
	else
		echo "RESULT: WARNING"
                echo "KDUMP NOT RUNNING"

	fi

elif [ ${OS_VERSION} -ge 7 ] && [ ${OS_VERSION} -le 9 ] ## FOR RHEL 7 to 9
then
	systemctl status kdump &> /dev/null
        rhel_dump_state=$?
        if [ ${rhel_dump_state} -eq 0 ]
        then
                cur_kdump_enable=$(systemctl is-enabled kdump)
                if [ ${cur_kdump_enable} == enabled ]
                then
                        echo "RESULT: OK"
                        echo
			systemctl status kdump 2> /dev/null
			echo
		else
			echo "RESULT: WARNING"
                        echo "KDUMP DAEMON STARTED BUT NOT ENABLED"
			echo
                        systemctl status kdump 2> /dev/null
                        echo
                fi
	else
                echo "RESULT: WARNING"
                echo "KDUMP DAEMON NOT STARTED"
	fi

else
	echo "RHEL${OS_VERSION} is not support version" 
fi

echo 
echo "=== End Kdump ==="
echo
}

MemoryInfo(){
echo
echo "=== MemoryInfo Check ==="
echo

cur_swap_total=$(cat /proc/meminfo | grep SwapTotal| awk '{print $2}')
cur_swap_Free=$(cat /proc/meminfo | grep SwapFree| awk '{print $2}')
let cur_swap_used_BYTE=$cur_swap_total-$cur_swap_Free

if [ $cur_swap_used_BYTE -eq 0 ];
then
        cur_swap_used_percent=0
else
        cur_swap_used_percent=$(echo $cur_swap_used_BYTE $cur_swap_total | awk '{print $1/$2*100}'| awk '{printf "%0.2f",$1}')
fi

echo "swap_total=${cur_swap_total} Byte"
echo "swap_free=${cur_swap_Free} Byte"
echo "swap_used_percent=${cur_swap_used_percent}%"


echo
echo "=== End MemoryInfo ==="
echo
}


main()
{
Hostname
OsVersion
FileSystem
UserInfo
NetworkPacket
NetworkRoute
BondingInfo
ZombieProcess
Uptime
NtpInfo
Kdump
MemoryInfo


#LogMessage
}

#main
MemoryInfo
