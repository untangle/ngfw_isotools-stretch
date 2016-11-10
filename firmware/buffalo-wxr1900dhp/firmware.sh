#! /bin/bash

set -e

CURRENT_DIR=$(dirname $0)
FMK_DIR=${CURRENT_DIR}/firmware-mod-kit

cd $(FMK_DIR) ; ./build-firmware.sh -min
