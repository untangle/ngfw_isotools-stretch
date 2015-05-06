#! /bin/bash

# This scripts requires the installation of virtualbox/wheezy and
# qemu-util/wheezy-backports

set -e
set -x

# constants
CURRENT_DIR=$(dirname $0)
CHROOT_DIR=$(mktemp -d /tmp/tmp.vmdk-chroot.XXXXX)
SETUP_SCRIPT="chroot-setup.sh"

# CL args
REPOSITORY=$1
DISTRIBUTION=$2
ORIGINAL_VMDK=$3
VMDK=$4

## main
QCOW2=${VMDK/.vmdk/.qcow2}

# NBD support
rmmod nbd || true
modprobe nbd max_part=16

# convert to qcow2
qemu-img convert -O qcow2 ${ORIGINAL_VMDK} ${QCOW2}

# attach and mount
qemu-nbd -d /dev/nbd0 || true
qemu-nbd -c /dev/nbd0 ${QCOW2}
sleep 3
mount /dev/nbd0p1 ${CHROOT_DIR}

# mount required PFS
for pfs in dev dev/pts proc sys ; do
  mount --bind /$pfs ${CHROOT_DIR}/$pfs
done

# setup Untangle in chroot
cp ${CURRENT_DIR}/${SETUP_SCRIPT} ${CHROOT_DIR}/tmp/
chroot ${CHROOT_DIR} /tmp/${SETUP_SCRIPT} ${REPOSITORY} ${DISTRIBUTION}

# umount PFS
for pfs in sys proc dev/pts dev ; do
  umount -l ${CHROOT_DIR}/$pfs || true
done

# free ressources, and cleanup
umount ${CHROOT_DIR}
qemu-nbd -d /dev/nbd0
rm -fr ${CHROOT_DIR}

# convert back to an ESX-compatible VMDK
qemu-img convert -O vmdk -o subformat=streamOptimized ${QCOW2} /tmp/tmp.vmdk
vboxmanage clonehd /tmp/tmp.vmdk ${VMDK} --format VMDK --variant Stream
