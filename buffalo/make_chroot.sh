#! /bin/bash

set -e
set -x

# constants
CURRENT_DIR=$(dirname $0)
CHROOT_DIR=$(mktemp -d /tmp/tmp.buffalo-chroot.XXXXX)
SECOND_STAGE_SCRIPT="second_stage.sh"

# CL args
REPOSITORY=$1
DISTRIBUTION=$2
ARCHIVE=$3

# we may run via sudo
export PATH=/sbin:/usr/sbin:${PATH}

# sane default locale
export LC_ALL=C

# arm emulation via binfmt
apt-get install --yes qemu qemu-user-static binfmt-support debootstrap
/etc/init.d/binfmt-support restart

# debootstrap onto chroot
debootstrap --arch=armel --foreign --no-check-gpg $REPOSITORY ${CHROOT_DIR} http://package-server/public/$REPOSITORY

# armel static binary in chroot
cp /usr/bin/qemu-arm-static ${CHROOT_DIR}/usr/bin/

# mount required PFS
for pfs in dev proc sys ; do
  mount --bind /$pfs ${CHROOT_DIR}/$pfs
done

# copy modules in chroot
cp ${CURRENT_DIR}/binary/modules.tar.bz2 ${CHROOT_DIR}/tmp/

# copy 2nd stage install script in chroot, and run it
cp ${CURRENT_DIR}/${SECOND_STAGE_SCRIPT} ${CHROOT_DIR}/tmp/
chroot ${CHROOT_DIR} /tmp/${SECOND_STAGE_SCRIPT} $REPOSITORY $DISTRIBUTION

# umount PFS
for pfs in sys proc dev/pts ; do
  umount -l ${CHROOT_DIR}/$pfs || true
done

# tar it all up
tar -C $CHROOT_DIR -cjf $ARCHIVE .

umount -l ${CHROOT_DIR}/dev || true

rm -fr $CHROOT_DIR
