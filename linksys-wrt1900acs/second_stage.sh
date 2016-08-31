#! /bin/bash

set -e

# constants
TMP_SOURCES_LIST="/etc/apt/sources.list.d/tmp.list"

# CL args
REPOSITORY=$1
DISTRIBUTION=$2
KERNEL_VERSION=$3

# disable starting of services
echo exit 101 > /usr/sbin/policy-rc.d
chmod +x /usr/sbin/policy-rc.d

# use internal Untangle repository
# FIXME: switch to only nightly later on
rm -f /etc/apt/sources.list $TMP_SOURCES_LIST
echo deb http://10.112.11.105/public/$REPOSITORY $DISTRIBUTION main non-free >> $TMP_SOURCES_LIST
echo deb http://10.112.11.105/public/$REPOSITORY ${DISTRIBUTION/nightly/chaos} main non-free >> $TMP_SOURCES_LIST

# install top-level Untangle package
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install --allow-unauthenticated --yes --force-yes -o DPkg::Options::=--force-confnew --fix-broken untangle-gateway
rm -f /usr/share/untangle/settings/untangle-vm/network.js

# root password
echo root:passwd | chpasswd

# for troubleshooting
DEBIAN_FRONTEND=noninteractive apt-get install --allow-unauthenticated --yes --force-yes bash-static

# install hardware-specific config
DEBIAN_FRONTEND=noninteractive apt-get install --allow-unauthenticated --yes --force-yes untangle-hardware-linksys-wrt1900acs

# install modules
mkdir -p /lib/modules/${KERNEL_VERSION}/extra
tar -C / -xjf /tmp/modules.tar.bz2
for mod in /tmp/*ko ; do 
  find /lib/modules/${KERNEL_VERSION} -name $(basename $mod) -exec rm -f {} \;
  cp $mod /lib/modules/${KERNEL_VERSION}/extra
done
depmod -a ${KERNEL_VERSION}

# install firmware
rsync -aH /tmp/firmware/ /lib/firmware/

# cleanup
apt-get clean
rm -fr $TMP_SOURCES_LIST /tmp/*

# re-enable starting of services
rm /usr/sbin/policy-rc.d

exit 0
