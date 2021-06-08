#!/bin/bash --

SERVICE_DIR="/usr/local/"

set -e

if [[ -r "${SERVICE_DIR}/staging/service.env" ]]; then
    source "${SERVICE_DIR}/staging/service.env"
fi

if [[ -r "${SERVICE_DIR}/staging/deploy.env" ]]; then
    source "${SERVICE_DIR}/staging/deploy.env"
fi

if [[ -r "${SERVICE_DIR}/staging/server.env" ]]; then
    source "${SERVICE_DIR}/staging/server.env"
fi

if [[ -x "${SERVICE_DIR}/tools/health_check.sh" ]]; then
    "${SERVICE_DIR}/tools/health_check.sh" || exit $?
fi
