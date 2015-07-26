#!/bin/bash

/bin/rm /usr/local/etc/primary_interface
#/usr/sbin/netstat -rn | awk '/default/ { print $6 }' > /usr/local/etc/primary_interface
enX=`/usr/sbin/networksetup -listnetworkserviceorder | grep Device | grep -m 1 en | awk ' { print $NF }' | sed 's/.$//'`

/bin/echo $enX > /usr/local/etc/primary_interface

exit 0
