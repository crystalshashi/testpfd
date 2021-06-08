#!/bin/bash

SERVICE_DIR="/usr/local"

set -e

main() {
    install_count="${1}"; shift

    if [[ "${install_count}" == "0" ]]; then
        echo "teardown p4 workspace..."
        teardown_p4_workspace

        echo "teardown configs..."
        teardown_configs
    fi

    echo "teardown tomcat..."
    teardown_tomcat
}

teardown_p4_workspace() (
    # clean up cron file
    /bin/rm -rvf /etc/cron.d/p4_sync

    # remove the workspace if it looks like we should
    if [[ -x /usr/local/bin/p4 && -d "${SERVICE_DIR}/config" ]]; then
        export P4CONFIG="p4config"
        cd ${SERVICE_DIR}/config || exit 0

        if [[ ! -r "./.creds" ]]; then
            echo "WARN: no credentials to remove p4 client" >&2
        elif [[ ! -r "${P4CONFIG}" ]]; then
            echo "WARN: no credentials to remove p4 client" >&2
        else
            ticket="$(/usr/local/bin/p4 login -p <./.creds | egrep '^[A-Z0-9]{32}$')"
            if [[ -z "${ticket}" ]]; then
                echo "WARN: failed to login when attempting to remove p4 client" >&2
            else
                client_name="$(/usr/local/bin/p4 set P4CLIENT | cut -d' ' -f1 | cut -d'=' -f2)"

                if [[ -n "${client_name}" ]]; then
                    /usr/local/bin/p4 -P "${ticket}" sync ...#0 || :
                    /usr/local/bin/p4 -P "${ticket}" client -d "${client_name}" || :

                    /usr/local/bin/p4 -P "${ticket}" logout || :
                fi
            fi
        fi
    else
        [[ -x /usr/local/bin/p4 ]] || echo "WARN: /usr/local/bin/p4 is missing or non-executable"
        [[ -d "${SERVICE_DIR}/config" ]] || echo "WARN: ${SERVICE_DIR}/config is not a directory"
    fi
)

teardown_tomcat() (
    # remove service deploy configuration
    /bin/rm -rf "${SERVICE_DIR}/staging/service.env"

    # clear the tomcat staging and runtime areas
    /bin/rm -rf "${SERVICE_DIR}/staging/tomcat"       \
                "${SERVICE_DIR}/tomcat/bin/"*         \
                "${SERVICE_DIR}/tomcat/conf/"*        \
                "${SERVICE_DIR}/tomcat/lib/"*         \
                "${SERVICE_DIR}/tomcat/temp/"*        \
                "${SERVICE_DIR}/tomcat/webapps/"*     \
                "${SERVICE_DIR}/tomcat/work/"*

    echo "post teardown_tomcat remaining files..."
    find "${SERVICE_DIR}" -type f || :
)

teardown_configs() (
    # clean up copied/generated files
    /bin/rm -rf "${SERVICE_DIR}/config/.creds"                          \
                "${SERVICE_DIR}/config/p4config"                        \
                "${SERVICE_DIR}/config/defaults/XXX-defaults.xml"       \
                "${SERVICE_DIR}/config/defaults/env-defaults.xml"       \
                "${SERVICE_DIR}/staging/deploy.env"                     \
                "${SERVICE_DIR}/staging/server.env"                     \
                "${SERVICE_DIR}/staging/service.env"

    /bin/rm -rf "${SERVICE_DIR}/pingfederate-9.3.3/"*                   \
                "${SERVICE_DIR}/pingfederate/"*                         


    echo "post teardown_configs remaining files..."
    find "${SERVICE_DIR}" -type f || :
)

main "$@"
exit "$?"
