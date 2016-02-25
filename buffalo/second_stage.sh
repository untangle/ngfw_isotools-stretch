#! /bin/bash

set -e

# constants
TMP_SOURCES_LIST="/etc/apt/sources.list.d/tmp.list"

# CL args
REPOSITORY=$1
DISTRIBUTION=$2
KERNEL_VERSION=$3

# complete installation
/debootstrap/debootstrap --second-stage

# disable starting of services
echo exit 101 > /usr/sbin/policy-rc.d
chmod +x /usr/sbin/policy-rc.d

# use internal Untangle repository
# FIXME: switch to nightly later on
echo deb http://10.112.11.105/public/$REPOSITORY $DISTRIBUTION main non-free > $TMP_SOURCES_LIST
echo deb http://10.112.11.105/public/$REPOSITORY nightly main non-free >> $TMP_SOURCES_LIST

# install top-level Untangle package
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install --allow-unauthenticated --yes --force-yes untangle-gateway
rm -f /usr/share/untangle/settings/untangle-vm/network.js

# for troubleshooting
DEBIAN_FRONTEND=noninteractive apt-get install --allow-unauthenticated --yes --force-yes bash-static

# install all the Buffalo-specific tweaks
DEBIAN_FRONTEND=noninteractive apt-get install --allow-unauthenticated --yes --force-yes untangle-hardware-buffalo-wzr1750
mkdir -p /lib/modules/${KERNEL_VERSION}
tar -C /lib/modules/${KERNEL_VERSION} -xjf /tmp/modules.tar.bz2
depmod -a ${KERNEL_VERSION}

# cleanup
apt-get clean
rm $TMP_SOURCES_LIST

# re-enable starting of services
rm /usr/sbin/policy-rc.d

exit 0
