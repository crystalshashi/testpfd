#!/bin/bash

# remove users/groups when last version removed
if [[ "$1" == "0" ]]; then
    # wait period if processes are still stopping
    sleep 5

    ! /usr/bin/getent passwd "app" 1>/dev/null 2>/dev/null  \
        || /usr/sbin/userdel -r "app"

    ! /usr/bin/getent group "appadmin" 1>/dev/null 2>/dev/null  \
        || /usr/sbin/groupdel "appadmin"
fi
