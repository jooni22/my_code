#!/bin/bash
# /home/mining_os/custom.sh
# This file is where you should put any custom scripting you would like to run.
# It will run once, after Xorg (Graphical interface) starts up, any commands which you absolutely have to run before xorg should be located$
# All scripting in this file should be before the "exit 0" as well.  Preface any commands which require 'root' privileges with the "sudo" c$
# Examples script running as user mining_os:
# my_command --my flags
# Example of a php script running as user root:
# sudo php /path/to/my/script.phpzxxxzz

################################################# SPRAWDZA CZY .bashrc ULEGL ZMIANIE

cmp -b bashrc.txt .bashrc
if [ "$?" != "0" ]; then
    cp /home/mining_os/bashrc.txt /home/mining_os/.bashrc
    bash
fi

################################################# ODPALA recustom.sh W KAŻDYM URUCHOMIENIU KOPARKI

if  [ -f "/home/mining_os/recustom.sh" ]; then
    sudo bash /home/mining_os/recustom.sh
fi

################################################# WPISUJE SIE W debug.txt

CZAS=$(date);
CUSTOM=$(cat /home/mining_os/debug.txt | tail -1);
echo "$CUSTOM | $CZAS custom" | sudo tee /home/mining_os/debug.txt

################################################# SEGREGUJE debug.txt
BASE=$(cat debug.txt | tail -1)
BASECP=$BASE
DBGSCRIPT=$(echo $BASE | tr -s '|' '\n' | grep 'script' | tail -1)
echo "LAST customscript: $DBGSCRIPT" >> /home/mining_os/debug.txt
DBGRECUSTOM=$(echo $BASE | tr -s '|' '\n' | grep 'recustom' | tail -1)
echo "LAST recustom: $DBGRECUSTOM" >> /home/mining_os/debug.txt
DBGCUSTOM=$(echo $BASE | tr -s '|' '\n' | grep 'custom' | tail -1)
echo "LAST custom: $DBGCUSTOM" >> /home/mining_os/debug.txt
echo "$BASECP" >> /home/mining_os/debug.txt
exit 0
