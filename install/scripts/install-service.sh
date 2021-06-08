#!/bin/bash
if [ $# -ne 1 ]; then
        echo "Usage: $0 <pingfederate staging location>\n"
        exit -1;
fi

#############################################################################################
# This script assumes that the /usr/local/pingfederate symlink exists and points to a valid
# PingFederate install location.
#############################################################################################

STAGING_DIR=$1

PINGFEDERATE_SERVICE_SYMLINKS=(
    /etc/rc0.d/K15pingfederate
    /etc/rc1.d/K15pingfederate
    /etc/rc2.d/K15pingfederate
    /etc/rc3.d/S84pingfederate
    /etc/rc4.d/S84pingfederate
    /etc/rc5.d/S84pingfederate
    /etc/rc6.d/K15pingfederate
)

echo "Copying $STAGING_DIR/scripts/pingfederate to /etc/rc.d/init.d/"
cp -rfpv $STAGING_DIR/scripts/pingfederate /etc/rc.d/init.d/pingfederate

echo "Changing file permissions on /etc/rc.d/init.d/pingfederate"
chmod 755 /etc/rc.d/init.d/pingfederate

echo "Creating /etc/rc.d/init.d/pingfederate symlinks..."
for PINGFEDERATE_SERVICE_SYMLINK in ${PINGFEDERATE_SERVICE_SYMLINKS[@]}
do
    ln -svf /etc/rc.d/init.d/pingfederate ${PINGFEDERATE_SERVICE_SYMLINK}
done
