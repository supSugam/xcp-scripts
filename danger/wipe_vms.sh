#!/bin/bash
echo "Shutting down all VMs..."
for vm in $(xe vm-list params=uuid --minimal | tr ',' ' '); do
    xe vm-shutdown uuid=$vm
done

echo "Uninstalling all VMs..."
for vm in $(xe vm-list params=uuid --minimal | tr ',' ' '); do
    xe vm-uninstall uuid=$vm force=true
done

echo "Deleting all VDIs..."
for vdi in $(xe vdi-list params=uuid --minimal | tr ',' ' '); do
    xe vdi-destroy uuid=$vdi
done

echo "Forgetting all Storage Repositories (SRs)..."
for sr in $(xe sr-list params=uuid --minimal | tr ',' ' '); do
    xe sr-forget uuid=$sr
done

echo "Re-scanning Storage Repositories..."
for sr in $(xe sr-list params=uuid --minimal | tr ',' ' '); do
    xe sr-scan uuid=$sr
done

echo "All VMs, VDIs, and SRs have been wiped!"
