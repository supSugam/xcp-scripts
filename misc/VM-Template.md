# Steps to Create a Ubuntu Installed VM Template

## Prerequisites:

- XCP-ng Host, with XOA VM running.
- A Storage Repository (SR) for ISOs, with it having the Ubuntu ISO.

## Steps:

1. Create a new VM, with the following settings:

### Info:

    - Pool: localhost
    - Name: Ubuntu-{Version}
    - Template: Other install media
    - Description: Ubuntu VM Template (Optional)

### Performance:

    - vCPUs: 1
    - Memory: 4GiB
    - Topology: Left as default

### Install Settings:

    - ISO/DVD, Ubuntu ISO Selected

### Interfaces:

    - eth0 Selected

### Disks:

    - SR: Local Storage
    - Name: Ubuntu-{Version}-Disk
    - Description: Created by XO
    - Size: 20GiB

### Advanced:

    - Auto Power On: Yes
    - Boot VM after creation: Yes
    - Dynamic Memory (MinMax): 3GiB - 4GiB
    - Static Memory (Max): 4GiB
    - Destroy cloud config drive after first boot: Yes

2. Click on create. It will eventually start the VM.

3. Switch to console tab to continue with the installation.

4. Follow the Ubuntu installation steps, leave most of the settings as default, agree to install `openssh` server.

5. Profile Configuration:

   - Server Name: ubuntu
   - Name: ubuntu
   - Password: ubuntu
   - Confirm Password: ubuntu

6. Installation will complete, and the VM will reboot, after it reboots, execute following commands:

   ```bash
   sudo apt update
   sudo apt dist-upgrade
   sudo apt install xe-guest-utilities cloud-init cloud-initramfs-growroot -y
   sudo dpkg-reconfigure cloud-init
   sudo rm -f /etc/cloud/cloud.cfg.d/99-installer.cfg
   sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg
   sudo rm -rf /var/lib/cloud/instance
   sudo rm -f /etc/netplan/00-installer-config.yaml
   sudo reboot
   ```

### Note: for Ubuntu 24.04, you will need to delete the /etc/cloud/cloud-init.disabled file, which disables Cloud-Init by default, and the /etc/netplan/50-cloud-init.yaml file for network configuration.

7. After the VM reboots, it will be ready to be converted into a template.

8. Shutdown the VM, and convert it into a template at XOA WebUI > VM > Advanced > Convert to Template.

9. The template is now ready to be used to create new VMs.

10. To create a new VM from the template, go to XOA WebUI > VM > New VM > Template > Ubuntu-{Version} or use clone.sh script.

### References:

- [XCP-ng Documentation](https://docs.xcp-ng.org/guides/create-use-custom-xcpng-ubuntu-templates/#from-an-iso-file)
