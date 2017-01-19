#! /bin/bash

set -e
set -x

# constants
TMP_SOURCES_LIST="/etc/apt/sources.list.d/tmp.list"
APT_OPTIONS="--allow-unauthenticated --yes --force-yes"

# CL args
REPOSITORY=$1
DISTRIBUTION=$2
ARCH=$3
shift 3
EXTRA_PACKAGES=$@

# disable starting of services
echo exit 101 > /usr/sbin/policy-rc.d
chmod +x /usr/sbin/policy-rc.d

# use internal Untangle repository
rm -f /etc/apt/sources.list
echo deb http://10.112.11.105/public/$REPOSITORY $DISTRIBUTION main non-free > $TMP_SOURCES_LIST
# FIXME
echo deb http://10.112.11.105/public/$REPOSITORY ${DISTRIBUTION/nightly/chaos} main non-free >> $TMP_SOURCES_LIST

apt-get update
apt-get install $APT_OPTIONS dpkg-dev untangle-debconf-manager

# remove user foo if present
userdel -f -r foo || true

# remove unncessary packages
KERNEL_ARCH="$(dpkg-architecture -qDEB_BUILD_ARCH)"
[[ $KERNEL_ARCH == "i386" ]] && KERNEL_ARCH="686"
perl -i -pe 's/3.16.0-4-amd64/3.16.0-4-amd64+fail/' /var/lib/dpkg/info/linux-image-3.16.0-4-amd64.prerm
DEBIAN_FRONTEND=noninteractive apt-get remove $APT_OPTIONS linux-image-3.16.0-4-${KERNEL_ARCH}

# install untangle-linux-config to work around #12857
mkdir -p /var/log/uvm
DEBIAN_FRONTEND=noninteractive DEBCONF_DEBUG=developer apt-get install $APT_OPTIONS -o Dpkg::Options::="--force-confnew" untangle-linux-config
# dist-upgrade in case of security updates since base VMDK was assembled
DEBIAN_FRONTEND=noninteractive DEBCONF_DEBUG=developer apt-get dist-upgrade $APT_OPTIONS -o Dpkg::Options::="--force-confnew"

# install vmware tools
DEBIAN_FRONTEND=noninteractive apt-get install $APT_OPTIONS open-vm-tools open-vm-tools-dkms

# install top-level Untangle package
DEBIAN_FRONTEND=noninteractive apt-get install $APT_OPTIONS untangle-gateway
rm -f /usr/share/untangle/settings/untangle-vm/network.js /usr/share/untangle/conf/uid

# install extra packages if any
if [[ -n "$EXTRA_PACKAGES" ]] ; then
  DEBIAN_FRONTEND=noninteractive apt-get install $APT_OPTIONS $EXTRA_PACKAGES
fi

# mark as OVA
touch /usr/share/untangle/conf/ova-flag

# remove duplicate keys
DEBIAN_FRONTEND=noninteractive apt-get install $APT_OPTIONS untangle-default-site

# fix / and swap
ROOT_UUID=$(blkid -o value /dev/nbd0p1 | head -1)
SWAP_UUID=$(blkid -o value /dev/nbd0p2 | head -1)
perl -i -pe 's/(UUID=[^\s]+|\/dev\/nbd0p1)/UUID='${ROOT_UUID}'/' /boot/grub/grub.cfg
perl -i -pe 's|UUID=[^\s]+\s+/|UUID='${ROOT_UUID}'\t/|' /etc/fstab
perl -i -pe 's|UUID=[^\s]+\s+none\s+swap|UUID='${SWAP_UUID}'\tnone\tswap|' /etc/fstab

# FIXME: remove keys, history, etc

# cleanup
apt-get clean
rm $TMP_SOURCES_LIST
rm /tmp/$(basename $0)

# re-enable starting of services
rm /usr/sbin/policy-rc.d

exit 0
