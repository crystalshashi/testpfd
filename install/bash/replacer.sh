#!/bin/bash --

SERVICE_DIR="/usr/local"

set -e

REPL_FILE="$1"

if [[ -r "${SERVICE_DIR}/staging/service.env" ]]; then
    source "${SERVICE_DIR}/staging/service.env"
fi

if [[ -r "${SERVICE_DIR}/staging/deploy.env" ]]; then
    source "${SERVICE_DIR}/staging/deploy.env"
fi

if [[ -r "${SERVICE_DIR}/staging/server.env" ]]; then
    source "${SERVICE_DIR}/staging/server.env"
fi

perl -pi -e 's/__(.+?)__/{exists $ENV{$1} ? $ENV{$1} : "__$1__"}/eg' $REPL_FILE

grep -q '__' $REPL_FILE && echo "WARNING: unreplaced parameters in file: ${REPL_FILE}" || :
