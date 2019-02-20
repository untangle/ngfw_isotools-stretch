#! /bin/bash

set -e
set -x

# CL args
IMAGE=$1

# include vendor-specific configuration
source image.conf

# variables
NAME=$(basename $(readlink -f .))
TARBALL_FILE=$(mktemp /tmp/tmp.${NAME}-tarball.XXXXX.tar.gz)
MNT_DIR=$(mktemp -d /tmp/tmp.${NAME}-img.XXXXX)

# mount IMG
losetup $LOOP_DEVICE  $IMAGE -o $(( 512 * 2048 ))
mount $LOOP_DEVICE $MNT_DIR

# tar up content
tar -C $MNT_DIR -czvf $TARBALL_FILE .

# umount
umount $MNT_DIR
losetup -d $LOOP_DEVICE

# re-create smaller disk image
dd if=/dev/zero of=$IMAGE bs=10M count=67
fdisk $IMAGE <<EOF
n
p
1


w
EOF

# format and mount it
losetup $LOOP_DEVICE  $IMAGE -o $(( 512 * 2048 ))
mkfs.ext4 $LOOP_DEVICE
mount $LOOP_DEVICE $MNT_DIR

# move tarball in
mv $TARBALL_FILE ${MNT_DIR}/omnia-medkit-last.tar.gz

# umount & cleanup
umount $MNT_DIR
losetup -d $LOOP_DEVICE
rm -fr $MNT_DIR
