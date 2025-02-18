#!/bin/bash

source load_config.sh
echo "Script executed from: ${PWD}"
echo "------------------------------"


# Copy all keys from ssh-keys file to the remote server using copy_ssh_keys.sh
source copy_ssh_keys.sh


# Use xe host-list to get the host UUID, using ssh
HOST_UUID=$(ssh $SSH_OPTS $HOST_USERNAME@$HOST_IP "xe host-list --minimal")

# Exit if host UUID is empty
if [[ -z "$HOST_UUID" ]]; then
    echo "Error: Host UUID is empty!"
    exit 1
fi

# Check if SR is created with this name: ISO_SR_NAME
ISO_SR_UUID=$(ssh $SSH_OPTS $HOST_USERNAME@$HOST_IP "xe sr-list name-label=$ISO_SR_NAME --minimal")

# If SR is not created, create it
if [[ -z "$ISO_SR_UUID" ]]; then
    echo "Creating ISO storage repository..."
    ssh $SSH_OPTS $HOST_USERNAME@$HOST_IP "xe sr-create name-label=$ISO_SR_NAME type=iso device-config:location=$ISO_SR_LOCATION device-config:legacy_mode=true content-type=iso"
    ISO_SR_UUID=$(ssh $SSH_OPTS $HOST_USERNAME@$HOST_IP "xe sr-list name-label=$ISO_SR_NAME --minimal")
    echo "ISO storage repository created!"
else
    echo "ISO storage repository already exists!"
fi


# Check if ISO file exists
if [[ ! -f "$ISO_FILEPATH" ]]; then
    echo "Error: File '$ISO_FILEPATH' not found!"
    exit 1
fi

# Check if ISO file is already uploaded at ISO_SR_LOCATION
UBUNTU_ISO_CHECK=$(ssh $SSH_OPTS $HOST_USERNAME@$HOST_IP "ls $ISO_SR_LOCATION | grep $ISO_FILENAME")
if [[ -z "$UBUNTU_ISO_CHECK" ]]; then
    echo "Copying $ISO_FILEPATH to $HOST_IP:$ISO_SR_LOCATION..."
    rsync -r -v --progress -e ssh $ISO_FILEPATH $HOST_USERNAME@$HOST_IP:$ISO_SR_LOCATION
    echo "ISO file copied!"
else
    echo "ISO file already exists!"
fi


# Check if both user-data and meta-data files exist in AUTOINSTALL_DIR
if [[ ! -f "$AUTOINSTALL_DIR/user-data" || ! -f "$AUTOINSTALL_DIR/meta-data" ]]; then
    echo "Error: user-data or meta-data file not found in $AUTOINSTALL_DIR!"
    exit 1
fi

# Check if seed.iso file exists at ISO_SR_LOCATION
SEED_ISO_CHECK=$(ssh $SSH_OPTS $HOST_USERNAME@$HOST_IP "ls $ISO_SR_LOCATION | grep 'seed.iso'")
if [[ -z "$SEED_ISO_CHECK" ]]; then
    echo "Creating seed.iso file..."
    # Delete seed.iso file if it already exists
    if [[ -f "seed.iso" ]]; then
        rm seed.iso
    fi
    # Create seed.iso file using cloud-localds
    cloud-localds seed.iso $AUTOINSTALL_DIR/user-data $AUTOINSTALL_DIR/meta-data
    rsync -r -v --progress -e ssh seed.iso $HOST_USERNAME@$HOST_IP:$ISO_SR_LOCATION
else
    echo "seed.iso file already exists!"
fi

# Rescan
ssh $SSH_OPTS $HOST_USERNAME@$HOST_IP "xe sr-scan uuid=$ISO_SR_UUID"

# Unattended VM Configuration
ssh $SSH_OPTS $HOST_USERNAME@$HOST_IP "xe vm-install template=Other\ install\ media new-name-label=$VM_NAME"

# Get the UUID of the VM
VM_UUID=$(ssh $SSH_OPTS $HOST_USERNAME@$HOST_IP "xe vm-list name-label=$VM_NAME --minimal")

# Set the VM memory
ssh $SSH_OPTS $HOST_USERNAME@$HOST_IP "xe vm-memory-limits-set dynamic-min='$VM_MEMORY' dynamic-max='$VM_MEMORY' static-min='$VM_MEMORY' static-max='$VM_MEMORY' uuid=$VM_UUID"

# Set the number of VCPUs
ssh $SSH_OPTS $HOST_USERNAME@$HOST_IP "xe vm-param-set VCPUs-max=$VM_VCPUS VCPUs-at-startup=$VM_VCPUS uuid=$VM_UUID"

# Set the VM disk size
LOCAL_STORAGE_SR_UUID=$(ssh $SSH_OPTS $HOST_USERNAME@$HOST_IP "xe sr-list type=lvm --minimal")
# ssh $SSH_OPTS $HOST_USERNAME@$HOST_IP "xe vm-disk-add disk-size=$VM_DISK_SIZE device=0 sr-uuid=$LOCAL_STORAGE_SR_UUID vm=$VM_UUID"

# Set the VM network
NETWORK_UUID=$(ssh $SSH_OPTS $HOST_USERNAME@$HOST_IP "xe network-list bridge=xenbr0 --minimal")
ssh $SSH_OPTS $HOST_USERNAME@$HOST_IP "xe vif-create vm-uuid=$VM_UUID network-uuid=$NETWORK_UUID device=0"

# Ensure SR is scanned
ssh $SSH_OPTS $HOST_USERNAME@$HOST_IP "xe sr-scan uuid=$ISO_SR_UUID"

# Create & attach VM disk
echo "Disk, $VM_DISK_SIZE, $VM_MEMORY"
DISK_VDI_UUID=$(ssh $SSH_OPTS $HOST_USERNAME@$HOST_IP "xe vdi-create name-label='$VM_NAME-Disk' sr-uuid=$LOCAL_STORAGE_SR_UUID virtual-size='$VM_DISK_SIZE' type=user")
ssh $SSH_OPTS $HOST_USERNAME@$HOST_IP "xe vbd-create vm-uuid=$VM_UUID vdi-uuid=$DISK_VDI_UUID device=0 bootable=true mode=RW type=Disk"

# Get ISO UUIDs
UBUNTU_ISO_UUID=$(ssh $SSH_OPTS $HOST_USERNAME@$HOST_IP "xe vdi-list name-label='$ISO_FILENAME' --minimal")
SEED_ISO_UUID=$(ssh $SSH_OPTS $HOST_USERNAME@$HOST_IP "xe vdi-list name-label='seed.iso' --minimal")

# Attach ISO as CD manually
ssh $SSH_OPTS $HOST_USERNAME@$HOST_IP "xe vbd-create vm-uuid=$VM_UUID vdi-uuid=$UBUNTU_ISO_UUID device=1 type=CD mode=RO bootable=true"
ssh $SSH_OPTS $HOST_USERNAME@$HOST_IP "xe vbd-create vm-uuid=$VM_UUID vdi-uuid=$SEED_ISO_UUID device=2 type=CD mode=RO bootable=false"

# Set boot order and use text console
ssh $SSH_OPTS $HOST_USERNAME@$HOST_IP "xe vm-param-set uuid=$VM_UUID HVM-boot-policy='BIOS order' PV-args='console=hvc0, autoinstall'"
ssh $SSH_OPTS $HOST_USERNAME@$HOST_IP "xe vm-param-set uuid=$VM_UUID HVM-boot-params:order=cd"

# Start the VM
ssh $SSH_OPTS $HOST_USERNAME@$HOST_IP "xe vm-start uuid=$VM_UUID"

# Attach to console and monitor
echo "Monitoring installation..."
ssh -t $SSH_OPTS $HOST_USERNAME@$HOST_IP "xe console uuid=$VM_UUID" &

# Wait for VM to finish installation
while true; do
    VM_POWER_STATE=$(ssh $SSH_OPTS $HOST_USERNAME@$HOST_IP "xe vm-list uuid=$VM_UUID params=power-state --minimal")
    
    if [[ "$VM_POWER_STATE" == "halted" ]]; then
        echo "Installation completed successfully!"
        exit 0
    elif [[ "$VM_POWER_STATE" == "running" ]]; then
        sleep 10  # Keep checking every 10 seconds
    else
        echo "Error: Unexpected VM state - $VM_POWER_STATE"
        exit 1
    fi
done
