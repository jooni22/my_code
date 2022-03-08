#!/bin/bash
sudo wget http://example.com/custom/pliki/gpu-info -O /opt/mining_os/sbin/gpu-info >/dev/null 2>&1
if ! [ -f "/var/run/mining_os/atiflash.file" ]; then
    sudo /opt/mining_os/sbin/gpu-info
fi
    removeBios=$(ls | grep ".rom" | xargs); 
    if [ -z "$removeBios" ]; then 
        echo "No bioses in /home/mining_os";
    else 
        sudo rm /home/mining_os/$removeBios
        echo "Old Bios $removeBios removed from /home/mining_os";
    fi 
j=0
i=1

for i in 1 2 3 4 5
do
    strapcopy=$(head -n $i /var/run/mining_os/atiflash.file | tail -1 | grep "StrapCopy");
    if [ -z "$strapcopy" ]; then
       disallow
       mem=$(head -n $i /var/run/mining_os/meminfo.file | tail -1 | cut -d":" -f4,5 | tr ' ' '_' | tr ':' '_');
        if ! [ -f "/home/mining_os/$mem.rom" ]; then
            sudo wget http://example.com/custom/rom/$mem.rom -O /home/mining_os/$mem.rom >/dev/null 2>&1;
            ls | grep "$mem.rom"
        fi
       sudo atiflash -p $j /home/mining_os/$mem.rom
     else
       echo 'GPU: '.$j.' already flashed.';
          fi
     j=$((j+1));
done;
/usr/bin/sudo /opt/mining_os/sbin/gpu-info;
allow
/usr/bin/sudo /sbin/reboot;
exit 0
exit 0
