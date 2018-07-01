#!/bin/bash

CLI_PACKAGE_URL=$1
AGENT_KEY_PATH=$2
PUBLIC_IP=$3
PRIVATE_IP=$4
MANAGER_USER=$5

echo "Installing Cloudify's CLI..."
echo "Using CLI package: ${CLI_PACKAGE_URL}"

which rpm

if [ "$?" -eq "0" ]; then
    sudo rpm -i ${CLI_PACKAGE_URL}
else
    wget ${CLI_PACKAGE_URL} -O cloudify-cli.deb
    sudo dpkg -i cloudify-cli.deb
fi

# This ensures that if one of the commands fails, the whole execution fails
set -e

cfy profiles use ${PRIVATE_IP} -u admin -p admin -t default_tenant

cfy blueprints upload cloudify-cosmo/cloudify-hello-world-example -b bp -n singlehost-blueprint.yaml
cfy deployments create -b bp dep -i server_ip=${PRIVATE_IP} -i agent_user=${MANAGER_USER} -i agent_private_key_path=${AGENT_KEY_PATH}
cfy executions start install -d dep

echo "Validating hello world is working..."
# Because of set -e, this will fail if the string isn't found in the output
curl http://${PRIVATE_IP}:8080 2>&1 | grep "Hello, World"

cfy executions start uninstall -d dep
cfy deployments delete dep
# Depoyment is deleted from DB AFTER delete_dep_env workflow ended successfully, this might take a second or two
sleep 4
cfy blueprints delete bp

echo "Test completed successfully!"
