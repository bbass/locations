#!/bin/bash

# Get primary interface
#primaryInt=`/usr/sbin/netstat -rn | awk '/default/ { print $6 }'`
primaryInt=`/usr/sbin/networksetup -listnetworkserviceorder | grep Device | grep -m 1 en | awk ' { print $NF }' | sed 's/.$//'`

CIDR=$(while read y; do echo ${y%.*}".0/$(m=0; while read -n 1 x && [ $x = f ]; do m=$[m+4]; done < <(ifconfig $primaryInt | awk '/mask/{$4=substr($4,3);print $4}'); echo $m )"; done < <(ifconfig $primaryInt | awk '/inet[ ]/{print $2}'))

echo "$CIDR"

exit 0
