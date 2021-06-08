#!/bin/bash

# Check if all args are present
if [ $# -ne 9 ]; then
    echo "Usage: $0 <pingfederate_install_directory> <source_configuration_directory> <pingfederate_installation_type> <cluster_mode> <server_index> <environment> <server_ip> <bind_port> <host_with_ports>\n"
    exit -1;
fi

PINGFEDERATE_INSTALL_DIR=$1
CONFIGURATION_DIR=$2
PINGFEDERATE_INSTALLATION_TYPE=$3
CLUSTER_MODE=$4
SERVER_INDEX=$5
ENVIRONMENT=$6
SERVER_IP=$7
BIND_PORT=$8
HOST_WITH_PORTS=$9

if [[ $CLUSTER_MODE != "STANDALONE" ]]; then
    echo "Starting token replacement..."
    sed -i s/__CLUSTEREDMODE__/$CLUSTER_MODE/1 $CONFIGURATION_DIR/$PINGFEDERATE_INSTALLATION_TYPE.run.properties
    sed -i s/__CLUSTEREDNODEINDEX__/$SERVER_INDEX/1 $CONFIGURATION_DIR/$PINGFEDERATE_INSTALLATION_TYPE.run.properties
    sed -i s/__SERVERIP__/$SERVER_IP/1 $CONFIGURATION_DIR/$PINGFEDERATE_INSTALLATION_TYPE.run.properties
    sed -i s/__CLUSTERBINDPORT__/$BIND_PORT/1 $CONFIGURATION_DIR/$PINGFEDERATE_INSTALLATION_TYPE.run.properties
    sed -i s/__HOSTSWITHBINDPORTS__/$HOST_WITH_PORTS/1 $CONFIGURATION_DIR/$PINGFEDERATE_INSTALLATION_TYPE.run.properties
fi
sed -i s/__ENVIRONMENT__/$ENVIRONMENT/1 $CONFIGURATION_DIR/$PINGFEDERATE_INSTALLATION_TYPE.run.properties

chmod -R 775 $CONFIGURATION_DIR
chown -R app:appadmin $CONFIGURATION_DIR

APPLICATION_LOG_DIRECTORY=/app/pingfederate/logs
if [ ! -d $APPLICATION_LOG_DIRECTORY ]; then
    mkdir -p $APPLICATION_LOG_DIRECTORY
fi
chown -R app:appadmin $APPLICATION_LOG_DIRECTORY

echo "Copying run.properties..."
cp -fv $CONFIGURATION_DIR/$PINGFEDERATE_INSTALLATION_TYPE.run.properties $PINGFEDERATE_INSTALL_DIR/bin/run.properties

echo "Copying run.sh..."
cp -fv $CONFIGURATION_DIR/run.sh $PINGFEDERATE_INSTALL_DIR/bin/run.sh

echo "Copying ldap.properties..."
if [[ $ENVIRONMENT == PRD* ]]; then
  cp -fv $CONFIGURATION_DIR/prod.ldap.properties $PINGFEDERATE_INSTALL_DIR/bin/ldap.properties
else
  cp -fv $CONFIGURATION_DIR/non-prod.ldap.properties $PINGFEDERATE_INSTALL_DIR/bin/ldap.properties
fi

echo "Copying jetty-runtime.xml..."
cp -fv $CONFIGURATION_DIR/jetty-runtime.xml $PINGFEDERATE_INSTALL_DIR/etc/jetty-runtime.xml

echo "Copying log4j2.xml..."
cp -fv $CONFIGURATION_DIR/log4j2.xml $PINGFEDERATE_INSTALL_DIR/server/default/conf/log4j2.xml

echo "Creating symlinks for admin server archive backup..."
cp -fv $CONFIGURATION_DIR/extractarc.sh $PINGFEDERATE_INSTALL_DIR/bin/extractarc.sh
cp -fv $CONFIGURATION_DIR/source.conf $PINGFEDERATE_INSTALL_DIR/bin/source.conf
cp -fv $CONFIGURATION_DIR/p4sync_jobs.sh $PINGFEDERATE_INSTALL_DIR/bin/p4sync_jobs.sh

echo "Copying session cookie config XML..."
cp -fv $CONFIGURATION_DIR/$PINGFEDERATE_INSTALLATION_TYPE.session-cookie-config.xml $PINGFEDERATE_INSTALL_DIR/server/default/data/config-store/session-cookie-config.xml

echo "Creating symlinks for http-request-parameter-validation and HandleAuthnRequest"
rm -fv $PINGFEDERATE_INSTALL_DIR/server/default/data/config-store/http-request-parameter-validation.xml
cp -fv  $CONFIGURATION_DIR/http-request-parameter-validation.xml $PINGFEDERATE_INSTALL_DIR/server/default/data/config-store/http-request-parameter-validation.xml

rm -fv $PINGFEDERATE_INSTALL_DIR/server/default/data/config-store/org.sourceid.saml20.profiles.idp.HandleAuthnRequest.xml
cp -fv  $CONFIGURATION_DIR/org.sourceid.saml20.profiles.idp.HandleAuthnRequest.xml $PINGFEDERATE_INSTALL_DIR/server/default/data/config-store/org.sourceid.saml20.profiles.idp.HandleAuthnRequest.xml

echo "Linking PingFederate configuration from Perforce..."
DATA_ZIP=/usr/local/config/configs/data.zip
ln -sf $DATA_ZIP $PINGFEDERATE_INSTALL_DIR/server/default/data/drop-in-deployer/data.zip
