#!/bin/bash

if [ "$(whoami)" != "root" ]
then
  echo "You have to run this script as Superuser!"
  exit 1
fi


freemem_before=$(cat /proc/meminfo | grep MemFree | tr -s ' ' | cut -d ' ' -f2) && freemem_before=$(echo "$freemem_before/1024.0" | bc)
cachedmem_before=$(cat /proc/meminfo | grep "^Cached" | tr -s ' ' | cut -d ' ' -f2) && cachedmem_before=$(echo "$cachedmem_before/1024.0" | bc)


echo -e "This script will clear cached memory and free up your ram.\n\nAt the moment you have $cachedmem_before MiB cached and $freemem_before MiB free memory."


if [ "$?" != "0" ]
then
  echo "Something went wrong, It's impossible to sync the filesystem."
  exit 1
fi


sync && echo 3 > /proc/sys/vm/drop_caches

freemem_after=$(cat /proc/meminfo | grep MemFree | tr -s ' ' | cut -d ' ' -f2) && freemem_after=$(echo "$freemem_after/1024.0" | bc)


echo -e "This freed $(echo "$freemem_after - $freemem_before" | bc) MiB, so now you have $freemem_after MiB of free RAM."

exit 0 
