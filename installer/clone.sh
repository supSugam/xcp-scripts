#!/bin/bash

source "${PWD}/config.env"

# Check if xo-cli npm package is installed
if ! command -v xo-cli &> /dev/null; then
    echo "xo-cli is not installed. Installing it..."
    npm install -g xo-cli
fi

# Unregister xo-cli
xo-cli unregister

# Login XO
xo-cli register --allowUnauthorized https://$XOA_VM_IP $XOA_LOGIN_USERNAME $XOA_LOGIN_PASSWORD

# Retrieve the necessary IDs
TEMPLATE_UUID=$(xo-cli xo.getAllObjects --json filter=json:'{"type":"VM-template", "name_label":"'"$TEMPLATE_NAME"'"}' | jq -r '.[].id')

# Exit if no template is found
if [ -z "$TEMPLATE_UUID" ]; then
    echo "No template found with the name $TEMPLATE_NAME"
fi
echo "Template UUID: $TEMPLATE_UUID"
exit 1


# STORAGE_UUID=$(xo-cli xo.getAllObjects --json filter=json:'{"type":"SR", "name_label":"'"$STORAGE_NAME"'"}' | jq '.[].id')
NETWORK_UUID=$(xo-cli xo.getAllObjects --json filter=json:'{"type":"network", "name_label":"'"$NETWORK_NAME"'"}' | jq '.[].id')

# Exit if no network is found
if [ -z "$NETWORK_UUID" ]; then
    echo "No network found with the name $NETWORK_NAME"
    exit 1
fi

# cloudConfig="$(cat templates/cloud-config)"
VM_UUID=$(xo-cli vm.create networkConfig="$(cat templates/network-config)" bootAfterCreate=true clone=true name_label="$VM_NAME" template=$TEMPLATE_UUID VIFs='json:[{"network":'$NETWORK_UUID'}]' hvmBootFirmware=bios copyHostBiosStrings=true)

# Exit if VM creation fails
if [ -z "$VM_UUID" ]; then
    echo "VM creation failed"
    exit 1
fi

echo "VM $VM_NAME using the template: $TEMPLATE_NAME created, VM UUID: $VM_UUID"