#!/bin/bash

## OS X Location Switcher
## Created by Brian Bass
## Revision 2.3.1
## 24 Jul 2015
## Inspired by: http://tech.inhelsinki.nl/locationchanger/

# Pull required information
primaryInt=`cat /usr/local/etc/primary_interface`

# Only run this script if there is a DHCP lease
while [ 1 ]; do
	if [[ $(ls /var/db/dhcpclient/leases/ | grep $primaryInt) != "" ]]; then
     		break
	fi
	/bin/sleep 3
done

# Make sure application level firewall is "on".
alfStatus=`/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate | /usr/bin/grep -i enabled`
if [ "$alfStatus" = "" ]; then
	/usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
	/bin/echo "Enabling firewall..."
fi

# Check to make sure that we haven't just booted the machine. If so, wait a bit longer.
epochTime=`date +%s`
bootTime=`sysctl -n kern.boottime | cut -c9-18`
count=`expr $epochTime - $bootTime`
bootDelay=60
normalDelay=15

if [ "$count" -lt 150 ]; then
	/bin/echo "This machine was booted $count seconds ago. Waiting $bootDelay seconds..."
	/bin/sleep $bootDelay
else
	/bin/echo "Letting things shake out a bit. We'll continue in $normalDelay seconds..."
	/bin/sleep $normalDelay
fi

# Dropbox doesn't play well with this so we'll work around that
/usr/bin/osascript -e 'tell application "Dropbox" to quit'

# Make sure we have the default locations configured.
locList="Default 46G Trusted"
for location in $locList; do
	if [[ `/usr/sbin/networksetup -listlocations | /usr/bin/grep $location` = "" ]]; then
		/usr/sbin/networksetup -createlocation $location populate
	fi
done

/bin/echo "All locations present and accounted for..."

selectedLoc=`/usr/sbin/networksetup -getcurrentlocation`
echo "Location: $selectedLoc"

# Set baseline security levels for each location
case $selectedLoc in
        46G )
                /usr/local/bin/locations.green
	;;
	Trusted )
		/usr/local/bin/locations.yellow
	;;
	* )
		/usr/local/bin/locations.red
	;;
esac

# Do some essential network discovery
CIDR=`/usr/local/bin/cidrCalc.sh`
echo "The current network is: $CIDR"

# Get wi-fi interface
wifiInt=`/usr/sbin/networksetup -listallhardwareports | grep -A1 Wi-Fi | awk '/Device/ { print $2 }'`
echo "Wi-Fi interface: $wifiInt"

# Obtain current SSID
SSID=`/usr/sbin/networksetup -getairportnetwork $wifiInt | awk '{ print $4 }'`
/bin/echo "SSID: $SSID"

## Add this networking info to pf
# Remove old info
/bin/rm /etc/pf.anchors/anchor-currentNet
# Create new file with current network information
/bin/echo "pass in quick from $primaryInt:network to any" > /etc/pf.anchors/anchor-currentNet

# Reload pf ruleset now that we are on a new network
/bin/echo "Reloading pf..."
/sbin/pfctl -F all -f /etc/net.armadillotech.pf.conf

# Flush pf custom firewall ruleset
/bin/echo "Flushing pf rules..."
/sbin/pfctl -a custom -F rules

# Take a pause for the cause
/bin/sleep 1

# Based on location, load appropriate pf anchor
currentLoc=`/usr/sbin/networksetup -getcurrentlocation`
case $currentLoc in
	46G )
		# Load appropriate changes to the pf "custom" anchor
		/sbin/pfctl -a custom -f /etc/pf.anchors/anchor-currentNet
	;;
	Trusted )
		# Load appropriate changes to the pf "custom" anchor
		/sbin/pfctl -a custom -f /etc/pf.anchors/anchor-currentNet
	;;
	*)
		# Initiate VPN connection
		/usr/sbin/scutil --nc start VPN --user x3100785 --password sAy4ikpa4c --secret mysafety
	;;
esac

/usr/local/bin/getprimaryInt.sh

# Relaunch dropbox
/usr/bin/open -a /Applications/Dropbox.app

exit 0
