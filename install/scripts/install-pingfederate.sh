#!/bin/bash

if [ $# -ne 3 ]; then
        echo "Usage: $0 <pingfederate staging location> <pingfederate version> <license version>\n"
        exit -1;
fi

#############################################################################################
# This script assumes that the app user and appadmin group have already been created.
#############################################################################################

STAGING_DIR=$1
PFD_VERSION=$2
LICENSE_VERSION=$3

if [ -d /usr/local/pingfederate-$PFD_VERSION ]; then
    echo "/usr/local/pingfederate-$PFD_VERSION already exists. Removing previous installation."
    rm -rf /usr/local/pingfederate-$PFD_VERSION
fi

echo "Unzipping $STAGING_DIR/server/pingfederate-$PFD_VERSION to /usr/local"
unzip $STAGING_DIR/server/pingfederate-$PFD_VERSION -d /usr/local

echo "Copying $STAGING/license/$LICENSE_VERSION.pingfederate.lic to /usr/local/pingfederate-$PFD_VERSION/pingfederate/server/default/conf/"
cp -rpfv $STAGING_DIR/license/$LICENSE_VERSION.pingfederate.lic /usr/local/pingfederate-$PFD_VERSION/pingfederate/server/default/conf/pingfederate.lic

echo "Removing 1>/dev/null 2>/dev/null from /usr/local/pingfederate-$PFD_VERSION/pingfederate/sbin/pingfederate-run.sh"
sed -i 's@1>/dev/null 2>/dev/null@@' /usr/local/pingfederate-$PFD_VERSION/pingfederate/sbin/pingfederate-run.sh

echo -e "\n\n#############################################################################################"
echo -e "# Validating /usr/local/pingfederate-$PFD_VERSION/pingfederate/sbin/pingfederate-run.sh"
echo -e "# grep output:"
grep "\"\$PF_HOME/bin/run.sh\"" /usr/local/pingfederate-$PFD_VERSION/pingfederate/sbin/pingfederate-run.sh
echo "#############################################################################################\n\n"

echo "Changing ownership and file permissions."
chmod -R 775 /usr/local/pingfederate-$PFD_VERSION
chown -R app:appadmin /usr/local/pingfederate-$PFD_VERSION

echo "Creating /usr/local/pingfederate symlink to /usr/local/pingfederate-$PFD_VERSION/pingfederate/"
ln -sv /usr/local/pingfederate-$PFD_VERSION/pingfederate /usr/local/pingfederate
chown -h app:appadmin /usr/local/pingfederate
