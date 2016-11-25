#! /bin/bash

set -e

CURRENT_DIR=$(dirname $0)
BIN_DIR=${CURRENT_DIR}/binary

TMP_IMAGE=${CURRENT_DIR}/tmp/tmp.img

# dynamically create a 28M dummy squashfs filled with zeros
dd if=/dev/zero of=$3 bs=1MB count=28

# assemble the TRX file
${BIN_DIR}/trx -m 40000000 -o $TMP_IMAGE $2 -a 131072 $3

# run through trx_vendor to compute a correct TRX checksum
${BIN_DIR}/trx_vendor -i $TMP_IMAGE -r RT-AC88U,3.0.0.4,380,760,$1

