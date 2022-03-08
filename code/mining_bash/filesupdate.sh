#!/bin/sh
#

#pobiera liste wszystkich wlaczonych koparek wpietych pod switcha daj # jak nie chcesz zmieniac listy ip z iplist.txt
all=$(wget -qO- http://example.com/mining/index.php | grep -v "http://" | grep "[192]\.[168]\.[0-1]" | cut -d "<" -f 1,4 | sed -e 's/<td>/ /' | awk '!a[$0]++' > all.txt)
allip=$(cat all.txt | cut -d " " -f 1 > allip.txt)
#zlicza ile jest adresow ip w pliku iplist.txt

#nmap spr działające serwery
nmap=$(/usr/bin/screen -dmS switch bash -c 'nmap -n -sP 192.168.0.*/24 192.168.1.*/24 --exclude 192.168.0.200,192.168.1.200 | grep "for 192" | cut -d " " -f 5 > switchip.txt')
ilosc=$(cat all.txt | wc -l)

#zmienne pomocnicze
dolar="$"
host="host"
rack="rack"
hostname="(/opt/mining_os/sbin/mining_os-readdata hostname)"
rack_loc="(cat /home/mining_os/remote.conf)"

#wykonuje polecenia
sudo sshpass -p live parallel-ssh -h allip.txt -l mining_os -t 7 -O StrictHostKeyChecking=no -O UserKnownHostsFile=/dev/null -A -P "host=$dolar$hostname; rack=$dolar$rack_loc; echo $dolar$rack $dolar$host" > result.txt

#wypisuje dane
tput setaf 2
cat result.txt | grep -v "SUCCESS" | grep -v "FAILURE" | tr ":" " " | cut -d " " -f 1,3,4
rigON=$(cat result.txt | grep -v "SUCCESS" | grep -v "FAILURE" | tr ":" " " | cut -d " " -f 1,3,4)
rigONcount=$(cat result.txt | grep -v "SUCCESS" | grep -v "FAILURE" | tr ":" " " | cut -d " " -f 1,3,4 | wc -l)
tput setaf 1
cat result.txt | grep "FAILURE" | cut -d " " -f 4
rigOFF=$(cat result.txt | grep "FAILURE" | cut -d " " -f 4)
rigOFFcount=$(cat result.txt | grep "FAILURE" | cut -d " " -f 4 | wc -l)
tput sgr0
echo "----------------------"
tput setaf 2
echo $rigONcount
tput setaf 1
echo $rigOFFcount
tput sgr0
exit 0

