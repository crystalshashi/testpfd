#!/bin/bash

ROOT_DIR="/usr/local/config"

unset P4PORT P4CLIENT
export P4CONFIG="p4config"

if [[ ! -d "${ROOT_DIR}" ]]; then
    echo "Missing root directory: ${ROOT_DIR}" >&2
    exit 1
fi

cd "${ROOT_DIR}" || exit 1

# sleep a random few seconds to thin the herd
sleep "$(( (${RANDOM} % 14) + 1 ))"

ticket="$(/usr/local/bin/p4 login -p <"${ROOT_DIR}/.creds" | egrep '^[A-Z0-9]{32}$')"

if [[ -z "${ticket}" ]]; then
    echo "Failed to get login ticket" >&2
    exit 2
fi

/usr/local/bin/p4 -P "${ticket}" sync

/usr/local/bin/p4 -P "${ticket}" logout
