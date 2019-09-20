#! /bin/bash

set -e
set -x

# constants
CURRENT_DIR=$(dirname $0)
OVA_PACKAGES_FILE="${CURRENT_DIR}/default.packages"
PROFILES_DIR="${CURRENT_DIR}/../profiles"
UNTANGLE_PACKAGES_FILE="${PROFILES_DIR}/untangle.packages"
UNTANGLE_DOWNLOADS_FILE="${PROFILES_DIR}/untangle.downloads"
KERNEL_VERSION="4.9.0-11"

# CL args
REPOSITORY=$1
DISTRIBUTION=$2
ARCH=$3
VMDK=$4
SIZE=$5
FLAVOR=$6

## main
QCOW2=${VMDK/vmdk/qcow2}
TMP_VMDK="/tmp/${FLAVOR}.vmdk"
FLAVOR_PACKAGES_FILE="${PROFILES_DIR}/${FLAVOR}.packages"

# create comma-separated list of extra packages
extraPackages=$(grep -h -vE '^#' $OVA_PACKAGES_FILE $FLAVOR_PACKAGES_FILE $UNTANGLE_PACKAGES_FILE $UNTANGLE_DOWNLOADS_FILE | xargs)
extraPackages=${extraPackages// /,}

# install latest untangle-development-kernel's ut-mkimage
apt update
DEBIAN_FRONTEND=noninteractive apt install --yes untangle-development-kernel

# remove previous image if present
rm -f $QCOW2

# FIXME: stable is usually the release-x.y branch; as a 1st step, we
# prolly want to case $DISTRIBUTION and infer suite name accordingly.
# This will however not work if we ever need to maintain 3 branches at
# the same (which happened with master=14.0 + release-13.2 +
# release-13.1 for a while)
case $DISTRIBUTION in
  # FIXME: we this scheme it will be difficult to support more than 2
  # distributions, unless we try and tag current as "unstable" instead
  current) CODENAME=testing ;;
  *) CODENAME=stable ;;
esac
ut-qemu-mkimage -u -r $REPOSITORY -d $CODENAME -k $KERNEL_VERSION -s ${SIZE}G -p $extraPackages -f $QCOW2

# convert back to an ESX-compatible VMDK
qemu-img convert -O vmdk -o subformat=streamOptimized ${QCOW2} ${TMP_VMDK}
rm -f $QCOW2

#mv $TMP_VMDK $VMDK
# FIXME: investigate if this step is still needed with the more recent
# QEMU on stretch
vboxmanage clonehd ${TMP_VMDK} ${VMDK} --format VMDK --variant Stream
rm ${TMP_VMDK}
