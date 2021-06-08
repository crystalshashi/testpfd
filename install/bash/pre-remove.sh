#!/bin/bash

SERVICE_DIR="/usr/local"

if [[ -x "${SERVICE_DIR}/tools/teardown_service.sh" ]]; then
    "${SERVICE_DIR}/tools/teardown_service.sh" "${1}"
fi
