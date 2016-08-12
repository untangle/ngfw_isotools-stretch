#! /bin/bash

# FIMXE: does it get any nastier than this ??
# make that a CGI on package-server, for fucksake...

env

REMOTE_USER="buildbot@package-server"
SSH_OPTIONS="-o StrictHostKeyChecking=no"
TMP_DIR=/tmp/package-server-proxy_$$

ssh -v $SSH_OPTIONS $REMOTE_USER "rm -fr $TMP_DIR ; mkdir $TMP_DIR"
scp $SSH_OPTIONS -q *sh $REMOTE_USER:$TMP_DIR
ssh $SSH_OPTIONS $REMOTE_USER "cd $TMP_DIR ; $@"
rc=$?
ssh $SSH_OPTIONS $REMOTE_USER rm -fr $TMP_DIR

exit $rc
