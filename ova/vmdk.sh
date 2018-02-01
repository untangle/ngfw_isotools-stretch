#! /bin/bash

set -e
set -x

# constants
CURRENT_DIR=$(dirname $0)
SETUP_SCRIPT="chroot-setup.sh"

# CL args
REPOSITORY=$1
DISTRIBUTION=$2
ARCH=$3
VMDK=$4
FLAVOR=$5

## main
QCOW2=${VMDK/vmdk/qcow2}
TMP_VMDK="/tmp/${FLAVOR}.vmdk"
FLAVOR_PACKAGES_FILE="${CURRENT_DIR}/../profiles/${FLAVOR}.packages"

# create comma-separated list of extra packages
extraPackages=$(grep -h -vE '^#' ${CURRENT_DIR}/extra-packages.txt $FLAVOR_PACKAGES_FILE | xargs)
extraPackages=${extraPackages// /,}

# install latest untangle-development-kernel's ut-mkimage
apt-get update
apt-get install --yes untangle-development-kernel

# remove previous image if present
rm -f $QCOW2

# FIXME: stable is usually the branch; as a 1st step, we prolly want
# to case $DISTRIBUTION and infer suite name.
# This will however not work if we maintain 3 branches at the same
# (which happened with master=14.0 + release-13.2 + release-13.1 for a
# while)
ut-qemu-mkimage -u -r $REPOSITORY -d stable -s 80G -p $extraPackages -f $QCOW2

# convert back to an ESX-compatible VMDK
qemu-img convert -O vmdk -o subformat=streamOptimized ${QCOW2} ${TMP_VMDK}
rm -f $QCOW2

mv $TMP_VMDK $VMDK
# # FIXME: investigate if this step is still needed with the more recent
# # QEMU on stretch
# rm -f ${VMDK}
# vboxmanage clonehd ${TMP_VMDK} ${VMDK} --format VMDK --variant Stream
