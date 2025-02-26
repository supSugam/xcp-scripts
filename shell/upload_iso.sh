#!/bin/bash

source load_config.sh
echo "Script executed from: ${PWD}"
echo "------------------------------"

source copy_ssh_keys.sh
# https://cdn.openbsd.org/pub/OpenBSD/7.6/amd64/install76.img
# Default path (optional)
# Usage: ./upload_iso.sh "/path/to/iso" "name.iso"
ISO_FILEPATH=$1
ISO_FILENAME=$2
IS_LOCAL_FILE=1

# Check if ISO_FILEPATH is empty
if [[ -z "$ISO_FILEPATH" ]]; then
    echo "Error: ISO_FILEPATH is empty, Usage: ./upload_iso.sh "/path/to/iso""
    exit 1
fi

# Check if ISO file path is local (not remote) and file exists
if [[ ! -f "$ISO_FILEPATH" ]]; then
    echo "File '$ISO_FILEPATH' not found locally!"
    IS_LOCAL_FILE=0
fi

# Exit if ISO_FILEPATH is not a valid http or https URL
if [[ ! "$ISO_FILEPATH" =~ ^https?:// ]]; then
    echo "Error: ISO_FILEPATH is not a valid http or https URL!"
    exit 1
fi

# If ISO_FILENAME is empty, set it to the basename of ISO_FILEPATH
if [[ -z "$ISO_FILENAME" ]]; then
    ISO_FILENAME=$(basename $ISO_FILEPATH)
fi

# Check if SR is created with this name: ISO_SR_NAME
ISO_SR_UUID=$(ssh $SSH_OPTS $HOST_USERNAME@$HOST_IP "xe sr-list name-label=$ISO_SR_NAME --minimal")

# If SR is not created, create it
if [[ -z "$ISO_SR_UUID" ]]; then
    echo "Creating ISO storage repository..."
    ssh $SSH_OPTS $HOST_USERNAME@$HOST_IP "xe sr-create name-label=$ISO_SR_NAME type=iso device-config:location=$ISO_SR_LOCATION device-config:legacy_mode=true content-type=iso"
    ISO_SR_UUID=$(ssh $SSH_OPTS $HOST_USERNAME@$HOST_IP "xe sr-list name-label=$ISO_SR_NAME --minimal")
    echo "ISO storage repository created!"
fi

ALREADY_EXISTS=$(ssh $SSH_OPTS $HOST_USERNAME@$HOST_IP "ls $ISO_SR_LOCATION | grep $ISO_FILENAME")
# Exit if ISO file already exists
if [[ ! -z "$ALREADY_EXISTS" ]]; then
    echo "ISO file already exists at $ISO_SR_LOCATION!"
    exit 1
fi

# If ISO file is local, copy it to the remote server using rsync
if [[ $IS_LOCAL_FILE -eq 1 ]]; then
    echo "Copying $ISO_FILEPATH to $HOST_IP:$ISO_SR_LOCATION..."
    rsync -r -v --progress -e ssh $ISO_FILEPATH $HOST_USERNAME@$HOST_IP:$ISO_SR_LOCATION
    echo "ISO file copied!"
else
    # If ISO file is remote, exec a command on remote server to download it
    echo "Downloading $ISO_FILEPATH to $HOST_IP:$ISO_SR_LOCATION..."
    ssh $SSH_OPTS $HOST_USERNAME@$HOST_IP "wget --progress=bar:force -O $ISO_SR_LOCATION/$ISO_FILENAME $ISO_FILEPATH"
    echo "ISO file downloaded!"
fi

ssh $SSH_OPTS $HOST_USERNAME@$HOST_IP "xe sr-scan uuid=$ISO_SR_UUID"

#  bsd, xtrlxat, post-command: mail
# continue with ssh tomorrow
