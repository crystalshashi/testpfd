#!/bin/bash

# Check if all args are present
if [ $# -ne 3 ]; then
  echo "Usage: $0 <pingfederate_install_directory> <source_configuration_directory> <target_bin_directory>\n"
  exit -1;
fi

PINGFEDERATE_INSTALL_DIR=$1
CONFIGURATION_DIR=$2
BIN_DIR=$3

BACKUP_RESTORE_CRONTAB=$CONFIGURATION_DIR/pingfederate-conf-crontab
TARGET_P4SYNC_JOBS=$BIN_DIR/p4sync_jobs.sh

if [ ! -d "/configs" ]; then
  echo "Creating /configs directory for Perforce syncing..."
  chown -R app:appadmin /configs
  chmod -R a+w /configs
fi

echo "Copying Perforce syncjob script..."
cp -rfpv $CONFIGURATION_DIR/p4sync_jobs.sh $TARGET_P4SYNC_JOBS
chmod a+x $TARGET_P4SYNC_JOBS
chown app:appadmin $TARGET_P4SYNC_JOBS

echo "Setting up Perforce sync cron jobs..."
if [ -f /etc/cron.d/pingfederate-conf-crontab ]; then
 rm -f /etc/cron.d/pingfederate-conf-crontab
fi
crontab -u app -r
cp $BACKUP_RESTORE_CRONTAB /etc/cron.d/pingfederate-conf-crontab
chmod 600 /etc/cron.d/pingfederate-conf-crontab

echo "Restoring PingFederate configurations..."
sudo -u app $TARGET_P4SYNC_JOBS

rc=$?
if [[ $rc != 0 ]] ; then
    echo "ERROR: There was an issue installing the Perforce configuration and clientspec. Perforce sync may not be working correctly."
   exit $rc
fi
exit 0;
