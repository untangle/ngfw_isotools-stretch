#! /bin/bash

set -e

CURRENT_DIR=$(dirname $0)
BIN_DIR=${CURRENT_DIR}/binary

TMP_IMAGE=${CURRENT_DIR}/tmp/tmp.img

${BIN_DIR}/trx -m 40000000 -o $TMP_IMAGE $2 -a 131072 $3
${BIN_DIR}/trx_vendor -i $TMP_IMAGE -r RT-AC88U,3.0.0.4,380,760,$1

