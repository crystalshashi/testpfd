#!/bin/bash

# create groups/users when first version installed
if [[ "$1" == "1" ]]; then
    /usr/bin/getent group "appadmin" 1>/dev/null 2>/dev/null    \
        || /usr/sbin/groupadd -g 7200 "appadmin"

    /usr/bin/getent passwd "app" 1>/dev/null 2>/dev/null        \
        || /usr/sbin/useradd -m -u 7200 -g "appadmin" -c "App User" "app"
fi
