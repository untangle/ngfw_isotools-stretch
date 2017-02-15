#! /bin/bash

set -e
set -x

# constants
CURRENT_DIR=$(dirname $0)

# CL args
IMAGE=$1

# include vendor-specific configuration
VENDOR_DIR=${CURRENT_DIR}/../${NAME}
source ${VENDOR_DIR}/image.conf

TARBALL_FILE=$(mktemp /tmp/tmp.${NAME}-tarball.XXXXX.tar.gz)
MNT_DIR=$(mktemp -d /tmp/tmp.${NAME}-img.XXXXX)

# mount IMG
losetup $LOOP_DEVICE  $IMAGE -o $(( 512 * 2048 ))
mount $LOOP_DEVICE $MNT_DIR

# tar up content
tar -C $MNT_DIR -czvf $TARBALL_FILE .

# wipe out IMG content
rm -fr ${MNT_DIR:-/foo}/*

# move tarball back in
mv $TARBALL_FILE ${MNT_DIR}/omnia-medkit-last.tar.gz

# umount & cleanup
umount $MNT_DIR
losetup -d $LOOP_DEVICE
rm -fr $MNT_DIR
