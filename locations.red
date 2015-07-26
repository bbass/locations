#!/bin/bash

## Rules for Untrusted locations
## Created by Brian Bass
## Revision 1.0.0
## 16 Jul 2015

# firewall, stealth mode, and ssh are on. block all connections is off.
blockStatus=`/usr/libexec/ApplicationFirewall/socketfilterfw --getblockall | /usr/bin/grep -i enabled`
stealthStatus=`/usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode | /usr/bin/grep -i enabled`

if [ "$blockStatus" = "" ]; then
	/usr/libexec/ApplicationFirewall/socketfilterfw --setblockall on
fi

if [ "$stealthStatus" = "" ]; then
	/usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
fi

# Disable ARD by default
ardCheck=`ps -ax | grep -i ARDAgent`

case $ardCheck in
	*RemoteManagement* )
		/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart\
		 -deactivate -configure -access -off
		/bin/echo "ARD access has been disabled..."
	;;
	* )
	;;
esac

exit 0
