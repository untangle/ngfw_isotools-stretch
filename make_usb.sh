#! /bin/bash

set -e
set -x

ISOTOOLS_DIR=$(dirname $0)

IMG=$1
ISO_IMG=$(ls -t /tmp/iso-images/UNTANGLE*iso | head -1)

IMG_NAME=$(basename $IMG)
IMG_NOZIP=$(echo $IMG_NAME | perl -pe 's/\.gz$//')
MOUNT_POINT=/mnt
ISO_MOUNT_POINT=/mnt2

gunzip -c $IMG >| $IMG_NOZIP
umount -f $MOUNT_POINT || true
mount -o loop $IMG_NOZIP $MOUNT_POINT
df -h

# grab isolinux conf directly from the ISO image
mkdir -p $ISO_MOUNT_POINT
mount -o loop $ISO_IMG $ISO_MOUNT_POINT
cp $ISO_MOUNT_POINT/isolinux/* $MOUNT_POINT/
umount $ISO_MOUNT_POINT

# tweak conf a bit
mv $MOUNT_POINT/isolinux.cfg $MOUNT_POINT/syslinux.cfg
perl -i -pe 's|vmlinuz|linux| ; s|/install.\w+/|| ; s|gtk/initrd|initrdg|' $MOUNT_POINT/{gtk,txt}.cfg

cp -r $ISOTOOLS_DIR/cd-root/images $ISOTOOLS_DIR/tmp/extras/simple-cdd $MOUNT_POINT
cp $ISO_IMG $MOUNT_POINT/$(echo $(basename $ISO_IMG) | perl -pe 's|:||g')
umount $MOUNT_POINT
