#!/bin/bash

DATA_ZIP=/configs/data.zip
P4=/usr/local/bin/p4
PINGFEDERATE_INSTALL_DIR=/usr/local/pingfederate

export P4CONFIG=/usr/local/bin/p4config

$P4 sync -f $DATA_ZIP | grep updating
CHANGES=$?

if [ $CHANGES -eq 0 ] ; then
	ln -sf $DATA_ZIP $PINGFEDERATE_INSTALL_DIR/server/default/data/drop-in-deployer/data.zip
fi
