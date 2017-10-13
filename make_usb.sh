#! /bin/bash

set -e
set -x

ISOTOOLS_DIR=$(dirname $0)

BASE_IMG=$1
ISO_IMG=$2
OUT_IMG=$3
FLAVOR=$4

IMG_NAME=$(basename $BASE_IMG)
MOUNT_POINT=$(mktemp -d /tmp/tmp.untangle-usb.XXXXX)
ISO_MOUNT_POINT=$(mktemp -d /tmp/tmp.untangle-usb.XXXXX)

gunzip -c $BASE_IMG >| $OUT_IMG
umount -f $MOUNT_POINT || true
mount -o loop $OUT_IMG $MOUNT_POINT
df -h

# grab isolinux conf directly from the ISO image
mkdir -p $ISO_MOUNT_POINT
mount -o loop $ISO_IMG $ISO_MOUNT_POINT
cp $ISO_MOUNT_POINT/isolinux/* $MOUNT_POINT/
umount $ISO_MOUNT_POINT
rm -r $ISO_MOUNT_POINT

# tweak conf a bit
mv $MOUNT_POINT/isolinux.cfg $MOUNT_POINT/syslinux.cfg
perl -i -pe 's|vmlinuz|linux| ; s|/install.\w+/|| ; s|gtk/initrd|initrdg|' $MOUNT_POINT/{gtk,txt}.cfg

cp -r $ISOTOOLS_DIR/cd-root/images $MOUNT_POINT
mkdir $MOUNT_POINT/simple-cdd
cp $ISOTOOLS_DIR/profiles/{default.conf,default.downloads,default.excludes,default.packages,default.preseed,default.udebs,expert.preseed,${FLAVOR}.downloads,${FLAVOR}.packages,${FLAVOR}.preseed} $MOUNT_POINT/simple-cdd/
cat > $MOUNT_POINT/simple-cdd/simple-cdd.templates <<EOF
Template: simple-cdd/profiles
Type: multiselect
Choices: untangle, ${FLAVOR}, expert
Default: 
Description: Select profiles
 profiles are a simple description of common system types.
 select all that apply.
EOF

cp $ISO_IMG $MOUNT_POINT/$(echo $(basename $ISO_IMG) | perl -pe 's|:||g')
umount $MOUNT_POINT
rm -r $MOUNT_POINT
