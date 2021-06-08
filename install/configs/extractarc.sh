#!/bin/bash

### config

###Variables
DATA_ZIP=/configs/data.zip
PINGFEDERATE_BIN_DIR=/usr/local/pingfederate/bin
P4=/usr/local/bin/p4
PINGFEDERATE_INSTALL_DIR=/usr/local/pingfederate
THISHOST=$(hostname)
ECHO=/bin/echo


export P4CONFIG=/usr/local/bin/p4config

LOG_PATH="/app/pingfederate/logs/p4sync_job"
NAME=$(/bin/date '+%Y-%m-%d-%H:%M:%S')
LOG_FILE=$LOG_PATH$NAME.log
exec > $LOG_FILE 2>&1


##Log Info
$ECHO "" 
$ECHO $(/usr/bin/uptime)
$ECHO $(/bin/date)


### Check there are 2 PingFederate process running. If that's the case, it means that this is the active environment.
ISACTIVE=$(/bin/ps aux | /bin/grep pingfede | /bin/grep -vE 'grep|rc3|tail' | /bin/grep run.sh | /usr/bin/wc -l)
$ECHO "$ISACTIVE"
if [[ $ISACTIVE -eq 2 ]] ; then

    $ECHO "We have to Upload, as this host is ACTIVE."
    ### Check out the archive to allow overwriting
    $P4 revert $DATA_ZIP
    $P4 edit -t binary $DATA_ZIP

    ### Export the archive

    $PINGFEDERATE_BIN_DIR/configcopy.sh \
        -Dconfigcopy.conf.file=$PINGFEDERATE_BIN_DIR/source.conf \
        -Dconfig.archive.file=$DATA_ZIP \
        -Dcmd=exportconfigarchive \
        -Ddebug=true


    ##Log Info
    $ECHO ""
    $ECHO $(/usr/bin/uptime)
    $ECHO $(/bin/date)


    ### Submit backup to Perforce

    p4_output=$( $P4 submit -f leaveunchanged -d "Uploading PingFederate configuration backup $THISHOST" $DATA_ZIP 2>& 1 )
    #0 means we have uploaded the new config to the server
    $ECHO "Value of p4_output is $p4_output"
    if [ "$?" == "0" ]; then
        $ECHO "PingFed config has changed since last backup, new config saved to P4"
        exit_status=0
    else
        grep 'No files to submit.' <<< $p4_output > /dev/null
        if [ "$?" == "0" ]; then
            $ECHO "PingFed config has not changed since last backup, nothing to save to P4"
            exit_status=0
        else
            $ECHO "P4 submission seems to have failed. P4 output follows:"
            sed 's/^/    /' <<< $p4_output >> $LOG_FILE
            $ECHO "End of P4 output"
            exit_status=1
        fi
    fi


    ##Log Info
    $ECHO ""
    $ECHO $(/usr/bin/uptime)
    $ECHO $(/bin/date)


    ### Revert any files open for edit

    $P4 revert $DATA_ZIP


    ##Log Info
    $ECHO ""
    $ECHO $(/usr/bin/uptime)
    $ECHO $(/bin/date)

else
    $ECHO "We have to Sync, as this host is STANDBY."


    $ECHO "*********************************Synchronization START*********************************"
    ##Log Info
    $ECHO ""
    $ECHO $(/usr/bin/uptime)
    $ECHO $(/bin/date)

    $P4 sync -f $DATA_ZIP
    $P4 sync -f $DATA_ZIP | grep updating
    CHANGES=$?
    $ECHO $CHANGES

    if [ $CHANGES -eq 0 ] ; then
            $ECHO "There has been some changes in the P4 repository!"
            #ln -sf $DATA_ZIP $PINGFEDERATE_INSTALL_DIR/server/default/data/drop-in-deployer/data.zip
    fi

    $ECHO "*********************************Synchronization END*********************************"

fi

##Log Info
$ECHO ""
$ECHO $(/usr/bin/uptime)
$ECHO $(/bin/date)

### Clean up of the logs every 30 days

/bin/find $LOG_PATH* -type f -ctime +30 -exec rm -f {} \;

### Report status

exit $exit_status
