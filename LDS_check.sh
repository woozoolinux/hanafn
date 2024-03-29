#!/bin/bash

# This is System check script and available in RHEL6, RHEL7, RHEL8, RHEL9 version.
# Written by Linux Data System for Hana Financial Group.
# FileName: LDS_check.sh
# Versoin : 0.1.2v
# Date: 2024.01

# Language SET
LANG=C

# Vairable SET
DATE=$(date +%Y%m%d)
HOSTNAME=$(hostname)


# Requirement Check
rpm -qa | grep ^bc- &> /dev/null

bc_package=$(echo $?)

if [ ${bc_package} -ne 0 ]
then	
	echo "bc package is not installed"
	echo "Error"
	exit 1
fi

# Directory SET
MAINTENANCE_HOME=/root/LDS/maintenance
REPORT_FILE="${MAINTENANCE_HOME}/OS_Report_${HOSTNAME}_${DATE}"

if [ -f "$REPORT_FILE" ]; then
    echo "$REPORT_FILE already exists. Exiting script."
    exit 1
fi

# Version Check
OS_VERSION=`cat /etc/redhat-release | grep -v ^# | awk '{print $(NF-1)}' | cut -d. -f1`




# check MAIN PATH
if [ ! -d  "${MAINTENANCE_HOME}" ]; then
        mkdir -p ${MAINTENANCE_HOME}
fi

SystemInfo(){
echo "=== SystemInfo Check ==="
echo

cur_systeminfo=$(dmidecode -t system | grep "System Information" -A3)
echo "${cur_systeminfo}"

echo
echo "===  End SystemInfo ==="
echo
}

Hostname(){
echo "=== HostName Check ==="
echo

cur_hostname=$(hostname)
echo "hostname = ${cur_hostname}"

echo
echo "===  End HostName ==="
echo
}

kernelParameter(){
echo "=== kernelBootParameter Check ==="
echo

cur_kernelParameter=$(cat /proc/cmdline)
echo "hostname = ${cur_kernelParameter}"

echo
echo "===  End kernelBootParameter ==="
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

disk_usage=$(df -Ph / | sed -e '/^[0-9]/d' -e '1d'| egrep -v "([1-8].% | .%)")
usage_check=$(echo $?)

## If it's 0, it means that 90% or more has been detected, indicating a problematic state.
if [ ${usage_check} -eq 0 ]
then
        echo "FileSystem_RESULT=WARNING"
else
        echo "FileSystem_RESULT=OK"
fi

echo
df -Ph | grep -v tmpfs
echo

echo
echo "=== End FileSystem ==="
}
InodeUsage(){
echo
echo "=== InodeUsage Check ==="
echo 

idisk_usage=$(df -Pih / | sed -e '/^[0-9]/d' -e '1d'| egrep -v "([1-8].% | .%)")
iusage_check=$(echo $?)

## If it's 0, it means that 90% or more has been detected, indicating a problematic state.
if [ ${iusage_check} -eq 0 ]
then
        echo "InodeUsage_RESULT=WARNING"
else
        echo "InodeUsage_RESULT=OK"
fi

echo
df -Pih | grep -v tmpfs
echo

echo
echo "=== End InodeUsage ==="
}

LogMessage(){
echo
echo "=== LogMessage Check ==="
echo

LOG_CHECK=$(cat /var/log/messages* | egrep "^$(date -d '1 months ago' +%h)|^$(date +%h)" | egrep -iw '(I/O error|rejecting I/O to offline device|killing request|hostbyte=DID_NO_CONNECT|mark as failed|remaining active paths|parity|Abort command issued|Hardware Error|SYN flooding|fail|error|fault|down|WARN|Call Trace|reboo)'| egrep -i -v '(warn=True|auth|segfault|cdrom)'| egrep -i -v '(auth|segfault|cdrom|fd0|sr0|vxvm)'| egrep -v 'VCS' | egrep -v 'ACPI Error:\ SMBus|ACPI Error:\ Method parse|dockerd-current|Shutting Down Daemons|Shutting down..|sftp-server' | wc -l)

  if [ "$LOG_CHECK" -eq 0 ]; then
   echo "LOG_CHECK_RESULT=OK"
  else
   echo "LOG_CHECK_RESULT=WARNING"
  fi
echo

cat /var/log/messages* | egrep "^$(date -d '1 months ago' +%h)|^$(date +%h)" | egrep -iw '(I/O error|rejecting I/O to offline device|killing request|hostbyte=DID_NO_CONNECT|mark as failed|remaining active paths|parity|Abort command issued|Hardware Error|SYN flooding|fail|error|fault|down|WARN|Call Trace|reboo)'| egrep -i -v '(warn=True|auth|segfault|cdrom)'| egrep -i -v '(auth|segfault|cdrom|fd0|sr0|vxvm)'| egrep -v 'VCS' | egrep -v 'ACPI Error:\ SMBus|ACPI Error:\ Method parse|dockerd-current|Shutting Down Daemons|Shutting down..|sftp-server'
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
}

NetworkPacket(){
echo
echo "=== NetworkPacket Check ==="
echo

## Warning Trigger Condition
threshold=0.1

if [ ${OS_VERSION} == 6 ] ## FOR RHEL6
then
	for i in $(ls /sys/class/net/ | egrep -v "vnet|lo|macv|bonding_masters|veth")
        do
		cur_packets=$(ifconfig $i | grep "RX packets" | awk '{print $2}' | cut -d: -f2)
		cur_errors=$(ifconfig $i | grep "RX packets" | awk '{print $3}' | cut -d: -f2)
		cur_dropped=$(ifconfig $i | grep "RX packets" | awk '{print $4}' | cut -d: -f2)
		

                echo "interface=$i"
		
		## In the case where the 'rx packet' is 0, it is considered OK
		if [ ${cur_packets} -le 0 ]
		then	
			echo "rx_packet_error_RESULT=OK"
			echo "rx_packet_drop_RESULT=OK"
		else
			## Calculate the error and drop rates
			error_result=$(awk 'BEGIN {print ('$cur_errors'/'$cur_packets'*100)}')
			drop_result=$(awk 'BEGIN {print ('$cur_dropped'/'$cur_packets'*100)}')
			
			## If the error rate is 0.1% or higher, it is considered WARNING
			if (( $(echo "$error_result >= $threshold" | bc -l) )); then
			        echo "rx_packet_error_RESULT=WARNING"
	        		echo "rx_packet error rate is ${error_result}"
			else
	        		echo "rx_packet_error_RESULT=OK"
			fi
	
	
			## If the drop rate is 0.1% or higher, it is considered WARNING
			if (( $(echo "$drop_result >= $threshold" | bc -l) )); then
	        		echo "rx_packet_drop_RESULT=WARNING"
	        		echo "rx_packet drop rate is ${drop_result}"
			else
	        		echo "rx_packet_drop_RESULT=OK"
			fi
	
			echo
		fi

		cur_tx_packets=$(ifconfig $i | grep "TX packets" | awk '{print $2}' | cut -d: -f2)
		cur_tx_errors=$(ifconfig $i | grep "TX packets" | awk '{print $3}' | cut -d: -f2)
		cur_tx_dropped=$(ifconfig $i | grep "TX packets" | awk '{print $4}' | cut -d: -f2)

		## In the case where the 'tx packet' is 0, it is considered OK
		if [ ${cur_tx_packets} -le 0 ]
		then	
			echo "tx_packet_error_RESULT=OK"
			echo "tx_packet_drop_RESULT=OK"
		else
			## Calculate the error and drop rates
			tx_error_result=$(awk 'BEGIN {print ('$cur_tx_errors'/'$cur_tx_packets'*100)}')
			tx_drop_result=$(awk 'BEGIN {print ('$cur_tx_dropped'/'$cur_tx_packets'*100)}')
			
			## If the tx error rate is 0.1% or higher, it is considered WARNING
			if (( $(echo "$tx_error_result >= $threshold" | bc -l) )); then
			        echo "tx_packet_error_RESULT=WARNING"
	        		echo "tx_packet error rate is ${tx_error_result}"
			else
	        		echo "tx_packet_error_RESULT=OK"
			fi
	
	
			## If the tx drop rate is 0.1% or higher, it is considered WARNING
			if (( $(echo "$tx_drop_result >= $threshold" | bc -l) )); then
	        		echo "tx_packet_drop_RESULT=WARNING"
	        		echo "tx_packet drop rate is ${tx_drop_result}"
			else
	        		echo "tx_packet_drop_RESULT=OK"
			fi
	
			echo
		fi
                echo
	done

	## print packet info
	for i in $(ls /sys/class/net/ | egrep -v "vnet|lo|macv|bonding_masters|veth")
 	do
	 	ifconfig $i 2> /dev/null
	done

	echo


else	### FOR RHEL7 or higher

	for i in $(ls /sys/class/net/ | egrep -v "vnet|lo|macv|bonding_masters|veth")
 	do
		cur_packets=$(ifconfig $i  | grep "RX packets" | awk '{print $3}')
		cur_errors=$(ifconfig $i | grep RX | grep errors | awk '{print $3}')
		cur_dropped=$(ifconfig $i | grep RX | grep errors | awk '{print $5}')

		

                echo "interface=$i"
		
		## In the case where the 'rx packet' is 0, it is considered OK
		if [ ${cur_packets} -le 0 ]
		then	
			echo "rx_packet_error_RESULT=OK"
			echo "rx_packet_drop_RESULT=OK"
		else
			## Calculate the error and drop rates
			error_result=$(awk 'BEGIN {print ('$cur_errors'/'$cur_packets'*100)}')
			drop_result=$(awk 'BEGIN {print ('$cur_dropped'/'$cur_packets'*100)}')
			
			## If the error rate is 0.1% or higher, it is considered WARNING
			if (( $(echo "$error_result >= $threshold" | bc -l) )); then
			        echo "rx_packet_error_RESULT=WARNING"
	        		echo "rx_packet error rate is ${error_result}"
			else
	        		echo "rx_packet_error_RESULT=OK"
			fi
	
	
			## If the drop rate is 0.1% or higher, it is considered WARNING
			if (( $(echo "$drop_result >= $threshold" | bc -l) )); then
	        		echo "rx_packet_drop_RESULT=WARNING"
	        		echo "rx_packet drop rate is ${drop_result}"
			else
	        		echo "rx_packet_drop_RESULT=OK"
			fi
	
			echo
		fi

		cur_tx_packets=$(ifconfig $i  | grep "TX packets" | awk '{print $3}')
		cur_tx_errors=$(ifconfig $i | grep TX | grep errors | awk '{print $3}')
		cur_tx_dropped=$(ifconfig $i | grep TX | grep errors | awk '{print $5}')

		## In the case where the 'tx packet' is 0, it is considered OK
		if [ ${cur_tx_packets} -le 0 ]
		then	
			echo "tx_packet_error_RESULT=OK"
			echo "tx_packet_drop_RESULT=OK"
		else
			## Calculate the error and drop rates
			tx_error_result=$(awk 'BEGIN {print ('$cur_tx_errors'/'$cur_tx_packets'*100)}')
			tx_drop_result=$(awk 'BEGIN {print ('$cur_tx_dropped'/'$cur_tx_packets'*100)}')
			
			## If the tx error rate is 0.1% or higher, it is considered WARNING
			if (( $(echo "$tx_error_result >= $threshold" | bc -l) )); then
			        echo "tx_packet_error_RESULT=WARNING"
	        		echo "tx_packet error rate is ${tx_error_result}"
			else
	        		echo "tx_packet_error_RESULT=OK"
			fi
	
	
			## If the tx drop rate is 0.1% or higher, it is considered WARNING
			if (( $(echo "$tx_drop_result >= $threshold" | bc -l) )); then
	        		echo "tx_packet_drop_RESULT=WARNING"
	        		echo "tx_packet drop rate is ${tx_drop_result}"
			else
	        		echo "tx_packet_drop_RESULT=OK"
			fi
	
			echo
		fi
                echo
	done

	echo

	## print packet info
	for i in $(ls /sys/class/net/ | egrep -v "vnet|lo|macv|bonding_masters|veth")
 	do
	 	ifconfig $i 2> /dev/null
	done

	echo
fi

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

### If teaming is in use print team status
if [ $(nmcli connection show 2> /dev/null | awk '$3 == "team" {print $1}' | wc -l) -ne 0 ]; then

        for team in $(nmcli connection show | awk '$3 == "team" {print $1}')
        do
        teamdctl ${team} state > /dev/null 2>&1
        if [ $? -eq 0 ]; then
                if [ $(teamdctl ${team} state view -v | grep ifindex: -B1 | egrep -v "ifindex|\-" | wc -l) -eq 2 ]; then
                        echo "TeamInfo_RESULT=OK"
                else
                        echo "TeamInfo_RESULT=WARNING"
                fi

                ### print teaming info
                echo
                echo "interface = ${team}"
                echo
                teamdctl ${team} state 2> /dev/null
        fi
        done

fi


bonFlag=3
mbond=`lsmod | grep bond`
if [ -z "$mbond" ];then
        echo ""
        echo "BondingInfo_RESULT=WARNING"
        echo "bond check result: bonding module not loading"
else
        bondlist=`ls /proc/net/bonding/* 2> /dev/null`
        for i in $bondlist; do
                echo "interface = ${i}"
                cat $i
                bondNum=`cat $i | egrep -A1 "Slave Interface"  | grep up| wc -l`
                if [ "$bondNum" == 2 ]; then
                        bonFlag=0
                else
                        bonInterface=`ls $bondlist | awk -F"/" '{print $NF}'`
                        echo ""
                        echo ""
                        echo "BondingInfo_RESULT=WARNING"
                        echo "Check $bonInterface status!!"
                        echo ""
                        bonFlag=3
                fi
        done

if [ "$bonFlag" == 0 ]; then
        echo ""
        echo "BondingInfo_RESULT=OK"
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
  echo "ZombieProcess_RESULT=WARNING"
  echo "Zombie Process: $zombie "
  echo
  echo "Current zombie process status:"
  ps aux | head -1
  echo "$cur_zombie"
 else
  echo "No Zombie Process"
  echo "ZombieProcess_RESULT=OK"
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
   	echo "Uptime_RESULT=OK"
   	echo "UPTIME: $days days"
  	fi
  else
  echo -e "Uptime_RESULT=OK"	
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
                        echo "NtpInfo_RESULT: OK"
                        echo
                        service ntpd status
                        echo "Current Time:"
                        ntpq -p
                else
                        echo "NtpInfo_RESULT: WARNING"
                        echo "NTPD DAEMON STARTED BUT NOT ENABLED"
			echo
                        service ntpd status
                        echo "Current Time:"
			ntpq -p
                fi
        else
                echo "NtpInfo_RESULT: WARNING"
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
    			echo "NtpInfo_RESULT: OK"
			echo
			systemctl status ntpd
			echo
			ntpq -p
		else
			echo "NtpInfo_RESULT: WARNING"
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
    			echo "NtpInfo_RESULT: OK"
			echo
			systemctl status chronyd
			echo
			chronyc sources
		else
			echo "NtpInfo_RESULT: WARNING"
                        echo "CHRONYD DAEMON STARTED BUT NOT ENABLED"
			echo
                        systemctl status chronyd
                        echo
                        chronyc sources

		fi
    	else
		echo "NtpInfo_RESULT: WARNING"	
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
                	echo "NtpInfo=RESULT: OK"
			echo
                	systemctl status chronyd 2> /dev/null
			echo
			chronyc sources
		else
			echo "NtpInfo=RESULT: WARNING"
                        echo "CHRONYD DAEMON STARTED BUT NOT ENABLED"
			systemctl status chronyd 2> /dev/null
                        echo
                        chronyc sources
		fi
        else
                echo "NtpInfo=RESULT: WARNING"
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
	echo "Kdump_RESULT: WARNING"
	echo "kdump memory not set"
	return
fi

if [ ${OS_VERSION} == 6 ] ## FOR RHEL6
then
	service kdump status &> /dev/null
	rhel6_dump_state=$?
	if [ ${rhel6_dump_state} -eq 0 ]
	then
		cur_runlevel=$(cat /etc/inittab | grep -v ^# | grep ^id | cut -d: -f 2)
                cur_enabled=$(chkconfig --list | grep -w kdump | cut -d${cur_runlevel} -f 2 | awk '{print $1}' | cut -d: -f2)
		
		if [ ${cur_enabled} == on ]
                then
                        echo "Kdump_RESULT: OK"
                        echo
			service kdump status
			echo 
		else
			echo "Kdump_RESULT: WARNING"
                        echo "KDUMP DAEMON STARTED BUT NOT ENABLED"
                        service kdmup status
		fi
	else
		echo "Kdump_RESULT: WARNING"
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
                        echo "Kdump_RESULT: OK"
                        echo
			systemctl status kdump 2> /dev/null
			echo
		else
			echo "Kdump_RESULT: WARNING"
                        echo "KDUMP DAEMON STARTED BUT NOT ENABLED"
			echo
                        systemctl status kdump 2> /dev/null
                        echo
                fi
	else
                echo "Kdump_RESULT: WARNING"
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

#Memory Calculation
# used: total - free
# RSS:  total - free - buffers - cached


## gatehring memory info
cur_mem_total=$(cat /proc/meminfo | grep MemTotal| awk '{print $2}')
cur_mem_Free=$(cat /proc/meminfo | grep MemFree| awk '{print $2}')
cur_mem_cache=$(cat /proc/meminfo | grep ^Cached:| awk '{print $2}' )
cur_mem_buffer=$(cat /proc/meminfo | grep ^Buffers| awk '{print $2}' )
cur_swap_total=$(cat /proc/meminfo | grep SwapTotal| awk '{print $2}')
cur_swap_Free=$(cat /proc/meminfo | grep SwapFree| awk '{print $2}')

## calculation memory usage
let cur_swap_used_BYTE=$cur_swap_total-$cur_swap_Free
let cur_RSS_used_BYTE=$cur_mem_total-$cur_mem_Free-$cur_mem_buffer-$cur_mem_cache
cur_RSS_used_percent=$(echo $cur_RSS_used_BYTE $cur_mem_total | awk '{print $1/$2*100}'| awk '{printf "%0.2f",$1}')

## check if swap memory in use
if [ $cur_swap_used_BYTE -eq 0 ];
then
        cur_swap_used_percent=0
else
        cur_swap_used_percent=$(echo $cur_swap_used_BYTE $cur_swap_total | awk '{print $1/$2*100}'| awk '{printf "%0.2f",$1}')
fi

## Warning when RSS memory usage exceeds 80
if (( $(echo "${cur_RSS_used_percent} >= 80" | bc -l) )); then
    	echo "rss_memory_RESULT=WARNING"
	echo "RSS=${cur_RSS_used_percent}%"
else	
	echo "rss_memory_RESULT=OK"
	echo "RSS=${cur_RSS_used_percent}%"
fi

echo

## Warning when swap memory usage exceeds 50
if (( $(echo "${cur_swap_used_percent} >= 50" | bc -l) )); then
        echo "swap_memory_RESULT=WARNING"
	echo "SWAP=${cur_swap_used_percent}%"
else
        echo "swap_memory_RESULT=OK"
	echo "SWAP=${cur_swap_used_percent}%"
fi


echo
free -h


echo
echo "=== End MemoryInfo ==="
echo
}


CpuLoad(){
echo
echo "=== CpuLoad Check ==="
echo

cpu_count=$(cat /proc/cpuinfo | grep processor | wc -l)
load_average=$(w | head -1 | awk '{print $NF}')


cur_load=$(echo $cpu_count $load_average | awk '{print $2/$1*100}'| awk '{printf "%0.2f",$1}')


### Warning when load average exceeds 90
if (( $(echo "${cur_load} >= 90" | bc -l) )); then
	echo "CpuLoad_RESULT=WARNING"
	echo "load_average=${cur_load}%"
	echo "cpu_count=${cpu_count}"
else
	echo "CpuLoad_RESULT=OK"
	echo "load_average=${cur_load}%"
	echo "cpu_count=${cpu_count}"
fi


echo 
w | head -1

echo
echo "=== End CpuLoad ==="
echo
}


main()
{
SystemInfo     >> ${REPORT_FILE}
Hostname       >> ${REPORT_FILE}
kernelParameter>> ${REPORT_FILE}
OsVersion      >> ${REPORT_FILE}
FileSystem     >> ${REPORT_FILE}
InodeUsage     >> ${REPORT_FILE}
UserInfo       >> ${REPORT_FILE}
NetworkPacket  >> ${REPORT_FILE}
NetworkRoute   >> ${REPORT_FILE}
BondingInfo    >> ${REPORT_FILE}
ZombieProcess  >> ${REPORT_FILE}
Uptime         >> ${REPORT_FILE}
NtpInfo        >> ${REPORT_FILE}
Kdump          >> ${REPORT_FILE}
MemoryInfo     >> ${REPORT_FILE}
CpuLoad        >> ${REPORT_FILE}
LogMessage     >> ${REPORT_FILE}
}

main
