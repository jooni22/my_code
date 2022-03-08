#!/bin/bash
declare -a arr arr=("free -m | grep Swap | xargs"
    "grep Huge /proc/meminfo | grep Total | xargs"
    "grep transparent_hugepage /etc/default/grub"
    "grep deadline /sys/block/sd*/queue/scheduler"
    "yum info redhat-lsb-core | egrep 'Name|Arch|Packages'"
    "yum info glibc | egrep 'Name|Arch|Packages'"
    "yum info gdb | egrep 'Name|Arch|Packages'"
    "yum info cyrus-sasl-lib | egrep 'Name|Arch|Packages'"
    "yum info java-1.8.0-openjdk | egrep 'Name|Arch|Packages'"
    "yum info java-1.8.0-openjdk-devel | egrep 'Name|Arch|Packages'"
    "yum info git | egrep 'Name|Arch|Packages'"
    "sudo -l | egrep 'marklgic'"
    "grep 'marklgic' /etc/passwd"
    "ls /etc/marklogic.conf"
    "lsblk -o NAME,FSTYPE,SIZE,TYPE,MOUNTPOINT | egrep '/var/opt/MarkLogic*|/opt/MarkLogic|/MarkLogicLogs'"
    "df -h | egrep '/var/opt/MarkLogicBackup'"
    "ls /opt/logstash/ | grep -v cannot | grep 5.4"
    "id logstash | grep groups"
    );
for (( i = 0; i < ${#arr[@]} ; i++ )); do
    echo -e "Running: \e[97m${arr[$i]}\e[0m"
    eval ${arr[$i]} >result.tmp 2>error.tmp
    if [ $? -eq 0 ]; then
        echo -e "Status: \e[42m\e[97mOK\e[0m"
        cat result.tmp
        echo -e "\e[0m-------"
    else
        echo -e "Status: \e[41m\e[97mERROR\e[0m"
        if [ -s error.tmp ]; then
            cat error.tmp
        else
            GREP_ARG=$(echo ${arr[$i]} | cut -d " " -f2)
            echo "NOT FOUND: $GREP_ARG"
        fi
        echo -e "\e[0m-------"
    fi
        rm -rf error.tmp result.tmp
done
