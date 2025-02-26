#!/bin/bash

source load_config.sh

# Usage:
# ./copy_ssh_keys.sh <host_ip> <host_username> <ssh_keys_filepath>(Optional)
HOST_IP=$1
HOST_USERNAME=$2
SSH_KEYS_FILEPATH=$3

if [[ -z "$HOST_IP" ]]; then
    echo "Error: Missing host IP address!"
    exit 1
fi

if [[ -z "$HOST_USERNAME" ]]; then
    echo "Error: Missing host username!"
    exit 1
fi

if [[ ! -f "$SSH_KEYS_FILEPATH" ]]; then
    # Find public key file (ending with .pub) in ~/.ssh directory
    PUBLIC_KEY_FILEPATH=$(find ~/.ssh -type f -name "*.pub" | head -n 1)
    if [[ -z "$PUBLIC_KEY_FILEPATH" ]]; then
        echo "Error: No public key file found in ~/.ssh directory!"
        exit 1
    fi
    echo "Using public key file: $PUBLIC_KEY_FILEPATH"
    ssh-copy-id -i $PUBLIC_KEY_FILEPATH $HOST_USERNAME@$HOST_IP
    exit 0
fi

# Copy each public key to the remote server
while IFS= read -r key || [[ -n $key ]]; do
    if [[ -n "$key" ]]; then
        echo "Checking if key is already copied to $HOST_IP..."
        if ssh -o StrictHostKeyChecking=no $HOST_USERNAME@$HOST_IP "grep -q '$key' ~/.ssh/authorized_keys"; then
            echo "Key already exists on $HOST_IP, skipping..."
        else
            echo "Copying $key to $HOST_IP..."
            ssh -o StrictHostKeyChecking=no $HOST_USERNAME@$HOST_IP "echo $key >> ~/.ssh/authorized_keys"
        fi
    else
        echo "Skipping empty line."
    fi
done <"$SSH_KEYS_FILEPATH"
