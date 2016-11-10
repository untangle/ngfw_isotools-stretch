#! /bin/bash

set -e

CURRENT_DIR=$(dirname $0)
BIN_DIR=${CURRENT_DIR}/binary

cp $3 $2
# need to apt-get install lzma for this one to do the right
# thing (lzma from the xz package won't do)
lzma -k -1 -c $1 >> $2
