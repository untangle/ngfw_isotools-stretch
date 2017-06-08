#! /bin/bash -x

set -e

REPOSITORY=$1
DISTRIBUTION=$2

STABLE_DISTRIBUTION=testing
DISTRIBUTION_DIR=/var/www/public/$REPOSITORY/dists

for d in $STABLE_DISTRIBUTION jessie jessie-updates ; do
  :
#  sudo rm -f $DISTRIBUTION_DIR/$d
#  sudo ln -sf $DISTRIBUTION_DIR/$DISTRIBUTION $DISTRIBUTION_DIR/$d
done

#cd $DISTRIBUTION_DIR/$DISTRIBUTION
#sudo rm -f updates
#sudo ln -sf ./ ./updates
