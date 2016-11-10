#! /bin/bash

set -e

CURRENT_DIR=$(dirname $0)

{ dd if=$2 bs=3072k conv=sync; dd if=$3 bs=2048 conv=sync; } > $1
