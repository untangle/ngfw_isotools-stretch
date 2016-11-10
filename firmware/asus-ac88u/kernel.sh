#! /bin/bash

set -e

CURRENT_DIR=$(dirname $0)
BIN_DIR=${CURRENT_DIR}/binary

${BIN_DIR}/lzma_4k e $2 $1
