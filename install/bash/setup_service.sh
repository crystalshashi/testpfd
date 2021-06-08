#!/bin/bash

SERVICE_DIR="/usr/local"

#cd "${SERVICE_DIR}/tomcat"

if [[ -r "${SERVICE_DIR}/staging/service.env" ]]; then
    source "${SERVICE_DIR}/staging/service.env"
fi

if [[ -r "${SERVICE_DIR}/staging/deploy.env" ]]; then
    source "${SERVICE_DIR}/staging/deploy.env"
fi

if [[ -r "${SERVICE_DIR}/staging/server.env" ]]; then
    source "${SERVICE_DIR}/staging/server.env"
fi

main() {
    if [[ -n "${P4_SYNC_PORT}" ]]; then
        setup_p4_workspace

        if [[ -n "${P4_SYNC_CRON_SCHEDULE}" ]]; then
            setup_p4_sync_cron
        fi

        run_p4_sync
    fi

    setup_configs
}

setup_p4_workspace() (
    if [[ ! -x /usr/local/bin/p4 ]]; then
        echo "...skipping workspace setup; no /usr/local/bin/p4 executable" >&2
        exit 0
    fi

    # setup p4 client workspace and p4config file
    p4_config_content="P4PORT=${P4_SYNC_PORT}\n"

    if [[ -n "${P4_SYNC_USER}" ]]; then
        p4_config_content="${p4_config_content}P4USER=${P4_SYNC_USER}\n"
    fi

    if [[ -n "${P4_SYNC_PASSWORD}" ]]; then
        /bin/rm -f "${SERVICE_DIR}/config/.creds"
        /bin/touch "${SERVICE_DIR}/config/.creds"
        chmod 0600 "${SERVICE_DIR}/config/.creds"
        chown app:appadmin "${SERVICE_DIR}/config/.creds"
        printf "${P4_SYNC_PASSWORD}" >"${SERVICE_DIR}/config/.creds"
    fi

    p4_client_name="tmptob-$(hostname -s)"
    if [[ -n "${P4_SYNC_CLIENT_SUFFIX}" ]]; then
        p4_client_name="${p4_client_name}-${P4_SYNC_CLIENT_SUFFIX}"
    fi
    p4_config_content="${p4_config_content}P4CLIENT=${p4_client_name}\n"
    printf "${p4_config_content}" >"${SERVICE_DIR}/config/p4config"
    unset p4_config_content

    if [[ -n "${P4_SYNC_VIEWS})" ]]; then
        cd ${SERVICE_DIR}/config && (
            if [[ ! -r "./.creds" ]]; then
                echo "ERROR: no credentials to create p4 client" >&2
                exit 2
            fi

            export P4CONFIG="p4config"
            ticket="$(/usr/local/bin/p4 login -p <./.creds | egrep '^[A-Z0-9]{32}$')"
            if [[ -z "${ticket}" ]]; then
                echo "ERROR: failed to login when attempting to create p4 client" >&2
                exit 2
            fi

            client_name="$(/usr/local/bin/p4 set P4CLIENT | cut -d' ' -f1 | cut -d'=' -f2)"
            client_view="$(printf "\t%s //${client_name}/%s\n" ${P4_SYNC_VIEWS})"

            printf "Client: %s\nRoot: %s\nOptions: %s\nSubmitOptions: %s\nView:\n%s"                \
                "${client_name}" "$(pwd)"                                                           \
                "noallwrite noclobber compress unlocked nomodtime rmdir"                            \
                "revertunchanged"                                                                   \
                "${client_view}" | /usr/local/bin/p4 -P "${ticket}" client -i

            /usr/local/bin/p4 -P "${ticket}" logout
        )
    fi
)

setup_p4_sync_cron() (
    if [[ -d "/etc/cron.d" ]]; then
        sync_cmd="${SERVICE_DIR}/tools/p4_sync.sh"
        sync_log="/app/pingfederate/logs/p4_sync.log"
        cron_entry="${P4_SYNC_CRON_SCHEDULE} app ${sync_cmd} >>${sync_log} 2>&1"
        echo "${cron_entry}" >/etc/cron.d/p4_sync
    else
        echo "WARN: no /etc/cron.d directory to use for p4_sync" >&2
        exit 2
    fi
)

run_p4_sync() (
    sync_cmd="${SERVICE_DIR}/tools/p4_sync.sh"

    if [[ -x "${sync_cmd}" ]]; then
        sync_log="/app/pingfederate/logs/p4_sync.log"
        su -c "${sync_cmd} >>${sync_log} 2>&1" - app
    else
        echo "WARN: no executable sync script at: ${sync_cmd}" >&2
        exit 2
    fi
)

setup_configs() (

    "${SERVICE_DIR}/tools/setup_java_home.sh"

    "${SERVICE_DIR}/staging/scripts/install-pingfederate.sh" "${SERVICE_DIR}/staging" "${PINGFEDERATE_VERSION}" "${LICENSE_VERSION}"

    printf "Emptying jvm options"
    #comment the default JVM options and let it take from config.cap
    cat /usr/local/staging/configs/jvm-memory.options > /usr/local/pingfederate-9.3.3/pingfederate/bin/jvm-memory.options


    "${SERVICE_DIR}/tools/replacer.sh" "${SERVICE_DIR}/staging/configs/cluster.run.properties"
    "${SERVICE_DIR}/tools/replacer.sh" "${SERVICE_DIR}/staging/configs/standalone.run.properties"
    
    #"${SERVICE_DIR}/tools/replacer.sh" "/usr/local/staging/scripts/post_install.sh"
    "${SERVICE_DIR}/staging/scripts/post_install.sh" "${SERVICE_DIR}/pingfederate" "${SERVICE_DIR}/staging/configs" "${INSTALLATION_TYPE}" "${PFD_CLUSTER_MODE}" "${INDEX}" "${ENVIRONMENT}" "${PFD_IP}" "${BIND_PORT}" "${HOSTSWITHPORTS}"

    "${SERVICE_DIR}/staging/scripts/install-service.sh" "${SERVICE_DIR}/staging"

    sudo cp "${SERVICE_DIR}/staging/configs/pingfederate-conf-crontab" "/etc/cron.d/"

    sudo touch /etc/profile.d/java_opts.sh
    echo "JAVA_OPTS : ${JAVA_OPTS}"

    echo "Adding JAVA_OPTS"
    echo "export JAVA_OPTS=\"${JAVA_OPTS}\"" > /etc/profile.d/java_opts.sh
    # execute replacements
    #"${SERVICE_DIR}/tools/replacer.sh" "${SERVICE_DIR}/config/urlsserver.properties"
    #"${SERVICE_DIR}/tools/replacer.sh" "${SERVICE_DIR}/config/urls-auth.properties"
)
main "$@"
exit "$?"
