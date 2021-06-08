#!/bin/bash --

SERVICE_DIR="/app/urls"

if [[ -r "${SERVICE_DIR}/staging/service.env" ]]; then
    source "${SERVICE_DIR}/staging/service.env"
fi

if [[ -r "${SERVICE_DIR}/staging/deploy.env" ]]; then
    source "${SERVICE_DIR}/staging/deploy.env"
fi

if [[ -r "${SERVICE_DIR}/staging/server.env" ]]; then
    source "${SERVICE_DIR}/staging/server.env"
fi

# only run on node number 1
if [[ "${DEPLOY_NODE_NUM}" != "1" ]]; then
    exit 0;
fi

if [[ -z "${CHECK_ACTIVE_LOCAL_URL}" ]]; then
    echo "No 'CHECK_ACTIVE_LOCAL_URL' configuration set; aborting."
    exit 1;
fi

if [[ -z "${CHECK_ACTIVE_REMOTE_URL}" ]]; then
    echo "No 'CHECK_ACTIVE_REMOTE_URL' configuration set; aborting."
    exit 1;
fi

startServerFlag=$1;

currentdc_base_url="${CHECK_ACTIVE_LOCAL_URL}";
otherdc_base_url="${CHECK_ACTIVE_REMOTE_URL}";

authorization="${CHECK_ACTIVE_SECURE_HEADER_VALUE}";


echo "Checking local DC CAS status...."
status_code=$(/usr/bin/curl --connect-timeout 5 --max-time 5 -H "Authorization: $authorization" --write-out "%{http_code}" --silent --output /dev/null "$currentdc_base_url/cas-web/v3/status?dependencies=true")

case "${status_code}" in
    "000")
        echo "Local DC check request did not return a response"
        echo "...assuming to be the inactive DC"
        ;;
    "200")
        echo "Local DC check returned status code ${status_code}"
        if [[ "${startServerFlag}" == "true" ]]; then
            echo "...proceeding with deployment and server start"
            exit 0
        else
            echo "...aborting deploy, current DC is active and server is not set to start"
            exit 1
        fi
        ;;
    "401")
        echo "Local DC check returned status code ${status_code}"
        echo "...aborting deploy, authorization for the check failed"
        exit 1
        ;;
    *)
        echo "Local DC check returned status code ${status_code}"
        echo "...aborting deploy, unexpected response"
        exit 1
        ;;
esac

echo "Checking remote DC CAS status...."
status_code=$(/usr/bin/curl --connect-timeout 5 --max-time 5 -H "Authorization: $authorization" --write-out "%{http_code}" --silent --output /dev/null "$otherdc_base_url/cas-web/v3/status?dependencies=true")
case "${status_code}" in
    "000")
        echo "Remote DC check request did not return a response"
        echo "...assuming to be the inactive DC"
        ;;
    "200")
        echo "Remote DC check returned status code ${status_code}"
        if [[ "${startServerFlag}" == "true" ]]; then
            echo "...aborting deploy, remote DC is active but local server is set to start"
            exit 1
        else
            echo "...proceeding with deployment, local DC is inactive and server is not set to start"
            exit 0
        fi
        ;;
    "401")
        echo "Remote DC check returned status code ${status_code}"
        echo "...aborting deploy, authorization for the check failed"
        exit 1
        ;;
    *)
        echo "Remote DC check returned status code ${status_code}"
        echo "...aborting deploy, unexpected response"
        exit 1
        ;;
esac
