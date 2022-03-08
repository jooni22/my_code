#!/bin/bash


sshpass -p live parallel-ssh -p 10 -h ip.txt -l mining_os -t 10 -A -O StrictHostKeyChecking=no -O PubkeyAuthentication=no -O UserKnownHostsFile=/dev/null 'sudo mining_os-overclock' > /tmp/output

while [ ! -f /tmp/output ]; do sleep 1; done
LISTGOOD=$(cat /tmp/output | grep "SUCCESS" | cut -d " " -f 1,3,4)
LISTBAD=$(cat /tmp/output | grep "FAILURE" | cut -d " " -f 1,3,4)
CGOOD=$(cat /tmp/output | grep -c "SUCCESS")
CBAD=$(cat /tmp/output | grep -c "FAILURE")
printf "Udane: \n%s \n" "$LISTGOOD"
printf "Nieudane: \n%s \n" "$LISTBAD"
printf "Udane: %d Nieudane: %d\n" "$CGOOD" "$CBAD"
cp /tmp/output output.txt
rm -f /tmp/output
exit 0
