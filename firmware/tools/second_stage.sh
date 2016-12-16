#! /bin/bash

set -e

# constants
TMP_SOURCES_LIST="/etc/apt/sources.list.d/tmp.list"

# CL args
REPOSITORY=$1
DISTRIBUTION=$2
KERNEL_VERSION=$3
NAME=$4

# disable starting of services
echo exit 101 > /usr/sbin/policy-rc.d
chmod +x /usr/sbin/policy-rc.d

# use internal Untangle repository
# FIXME: switch to only nightly later on
rm -f /etc/apt/sources.list $TMP_SOURCES_LIST
echo deb http://10.112.11.105/public/$REPOSITORY $DISTRIBUTION main non-free >> $TMP_SOURCES_LIST
echo deb http://10.112.11.105/public/$REPOSITORY ${DISTRIBUTION/nightly/chaos} main non-free >> $TMP_SOURCES_LIST
apt-get update

# for troubleshooting
DEBIAN_FRONTEND=noninteractive apt-get install --allow-unauthenticated --yes --force-yes bash-static

# install hardware-specific config
DEBIAN_FRONTEND=noninteractive apt-get install --allow-unauthenticated --yes --force-yes untangle-hardware-${NAME}

# install top-level Untangle package
DEBIAN_FRONTEND=noninteractive apt-get install --allow-unauthenticated --yes --force-yes -o DPkg::Options::=--force-confnew --fix-broken untangle-gateway
rm -f /usr/share/untangle/settings/untangle-vm/network.js

# root password
echo root:passwd | chpasswd

# cleanup
apt-get clean
rm -fr $TMP_SOURCES_LIST /tmp/*

# re-enable starting of services
rm /usr/sbin/policy-rc.d

exit 0
