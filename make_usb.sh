#! /bin/bash

set -e
set -x

ISOTOOLS_DIR=$(dirname $0)

IMG=$1
ISOLINUX_CFG=$2
ISO_IMG=$(ls -t /tmp/iso-images/UNTANGLE*iso | head -1)

IMG_NAME=$(basename $IMG)
IMG_NOZIP=$(echo $IMG_NAME | perl -pe 's/\.gz$//')
MOUNT_POINT=/mnt
SYSLINUX_LOOP=$MOUNT_POINT/syslinux.cfg

gunzip -c $IMG >| $IMG_NOZIP
mount -o loop $IMG_NOZIP /mnt
df -h
cat $ISOLINUX_CFG | perl -pe 's|vmlinuz|linux| ; s|/install.\w+/|| ; s|gtk/initrd|initrdg|' >| $SYSLINUX_LOOP
cp -r $ISOTOOLS_DIR/cd-root/images $ISOTOOLS_DIR/tmp/extras/simple-cdd $MOUNT_POINT
cp $ISO_IMG $MOUNT_POINT/$(echo $(basename $ISO_IMG) | perl -pe 's|:||g')
umount /mnt
