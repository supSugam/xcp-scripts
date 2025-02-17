#!/bin/bash

source load_config.sh

#!/bin/bash

if [[ ! -f "$SSH_KEYS_FILEPATH" ]]; then
    echo "Error: File '$SSH_KEYS_FILEPATH' not found!"
    exit 1
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
done < "$SSH_KEYS_FILEPATH"
