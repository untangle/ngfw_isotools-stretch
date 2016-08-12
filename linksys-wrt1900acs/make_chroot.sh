#! /bin/bash

set -e
set -x

# constants
CURRENT_DIR=$(dirname $0)
CHROOT_DIR=$(mktemp -d /tmp/tmp.asus-ac88u-chroot.XXXXX)
MNT_DIR=$(mktemp -d /tmp/tmp.asus-ac88u-img.XXXXX)
SECOND_STAGE_SCRIPT="second_stage.sh"
LOOP_DEVICE="/dev/loop0"
# CL args
REPOSITORY=$1
DISTRIBUTION=$2
ARCH=$3
ASUS_ROOTFS=$4
IMAGE=$5

# we may run via sudo
export PATH=/sbin:/usr/sbin:${PATH}

# sane default locale
export LC_ALL=C

# arm emulation via binfmt
apt-get install --yes qemu qemu-user-static binfmt-support debootstrap
/etc/init.d/binfmt-support restart

# debootstrap onto chroot
debootstrap --arch=$ARCH --foreign --no-check-gpg $REPOSITORY ${CHROOT_DIR} http://package-server/public/$REPOSITORY

# armel static binary in chroot
case $ARCH in
  armel)
    KERNEL_VERSION="4.4.3"
    cp /usr/bin/qemu-arm-static ${CHROOT_DIR}/usr/bin/ ;;
  *)
    echo "can not handle arch '$ARCH', aborting..."
    exit 1 ;;
esac

# complete installation
chroot ${CHROOT_DIR} /debootstrap/debootstrap --second-stage

# mount required PFS
for pfs in dev dev/pts proc sys ; do
  mkdir -p ${CHROOT_DIR}/$pfs
  mount --bind /$pfs ${CHROOT_DIR}/$pfs
  mount
  ls ${CHROOT_DIR}/$pfs
done

# copy modules in chroot
cp ${CURRENT_DIR}/binary/modules.tar.bz2 ${CHROOT_DIR}/tmp/
cp ${CURRENT_DIR}/binary/modules/*ko ${CHROOT_DIR}/tmp/

# untar original Asus rootfs into /var/lib/asus-ac88u-rootfs
ROOTFS_DEST_DIR="${CHROOT_DIR}/var/lib/asus-ac88u-rootfs"
mkdir -p $ROOTFS_DEST_DIR
tar -C $ROOTFS_DEST_DIR -xajf ${CURRENT_DIR}/${ASUS_ROOTFS}

# copy 2nd stage install script in chroot, and run it
cp ${CURRENT_DIR}/${SECOND_STAGE_SCRIPT} ${CHROOT_DIR}/tmp/
chroot ${CHROOT_DIR} /tmp/${SECOND_STAGE_SCRIPT} $REPOSITORY $DISTRIBUTION $KERNEL_VERSION

# umount PFS
for pfs in sys proc dev/pts dev ; do
  umount -l ${CHROOT_DIR}/$pfs || true
done

umount -l ${CHROOT_DIR}/dev || true

# create disk image
dd if=/dev/zero of=$IMAGE bs=10M count=170
fdisk $IMAGE <<EOF
n
p
1


w
EOF

# mount it
losetup $LOOP_DEVICE  $IMAGE -o $(( 512 * 2048 ))
mkfs.ext4 $LOOP_DEVICE
mount $LOOP_DEVICE $MNT_DIR

# copy content
rsync -aHz ${CHROOT_DIR}/ ${MNT_DIR}

# umount & cleanup
umount $MNT_DIR
losetup -d $LOOP_DEVICE
rm -fr $CHROOT_DIR $MNT_DIR