#!/bin/bash --

SERVICE_DIR="/usr/local"

if [[ -r "${SERVICE_DIR}/staging/service.env" ]]; then
    source "${SERVICE_DIR}/staging/service.env"
fi

if [[ -r "${SERVICE_DIR}/staging/deploy.env" ]]; then
    source "${SERVICE_DIR}/staging/deploy.env"
fi

if [[ -r "${SERVICE_DIR}/staging/server.env" ]]; then
    source "${SERVICE_DIR}/staging/server.env"
fi

[[ -z "${SRVC_CHECK_URL}" ]] && echo "no SRVC_CHECK_URL value set" >&2 && exit 0
[[ -z "${SRVC_CHECK_DELAY}" ]] && SRVC_CHECK_DELAY=15
[[ -z "${SRVC_CHECK_INTERVAL}" ]] && SRVC_CHECK_INTERVAL=5
[[ -z "${SRVC_CHECK_RETRIES}" ]] && SRVC_CHECK_RETRIES=10

attempts=0
while [[ "${attempts}" -le "${SRVC_CHECK_RETRIES}" ]]
do
    attempts="$(( ${attempts} + 1 ))"

    if [[ "${attempts}" -eq 1 && "${SRVC_CHECK_DELAY}" -gt 0 ]] ; then
        echo "Sleeping ${SRVC_CHECK_DELAY} seconds to allow the server to start before checking health."
        sleep "${SRVC_CHECK_DELAY}"
    fi

    status_code=$(/usr/bin/curl --write-out "%{http_code}" --silent --output /dev/null "${SRVC_CHECK_URL}")
    if [[ "${status_code}" -eq "000" ]] ; then
        echo "Health check request did not return a response."
    else
        echo "Health check returned status code: ${status_code}"
    fi

    if [[ "${status_code}" -eq 200 ]] ; then
        echo -e "\n\n"
        echo "################################################################################################"
        echo "# Health check SUCCESS."
        echo "################################################################################################"
        exit 0;
    else
        echo "Sleeping ${SRVC_CHECK_INTERVAL} seconds to try again..."
        sleep "${SRVC_CHECK_INTERVAL}"
    fi
done

if [[ "${status_code}" -ne 200 ]] ; then
    echo -e "\n\n"
    echo "################################################################################################"
    echo "# Health check ERROR, status check final response: ${status_code}"
    echo "################################################################################################"
    exit 1;
else
    echo -e "\n\n"
    echo "################################################################################################"
    echo "# Health check SUCCESS."
    echo "################################################################################################"
    exit 0;
fi
