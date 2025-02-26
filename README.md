# Steps to Create a VM Template

## Prerequisites:

- XCP-ng Host, with XOA VM running.
- A Storage Repository (SR) for ISOs
- Your ISO file in the SR.

## Pre-Installation Steps:

1. Create `config.env` file, and set the variables accordingly (see `config.env.example`).

2. Use `shell/copy_ssh_keys.sh` script, it will copy your SSH keys to the XCP-ng host.

   ```bash
   Usage: ./copy_ssh_keys.sh
   ```

3. Use `shell/upload_iso.sh` script, it will create ISOs SR if not already created, and you can upload ISO either from your local machine or from the internet.
   ```bash
   Usage: ./upload_iso.sh [URL]
   Example: ./upload_iso.sh http://releases.ubuntu.com/20.04.3/ubuntu-20.04.3-live-server-amd64.iso
   ```

## Steps:

1. Create a new VM, with the following settings:

### Info:

    - Pool: localhost
    - Name: {OS_NAME}-{Version}
    - Template: Other install media
    - Description: {OS_NAME} VM Template (Optional)

### Performance:

    - vCPUs: 1
    - Memory: 4GiB
    - Topology: Left as default

### Install Settings:

    - ISO/DVD, {OS_NAME} ISO Selected

### Interfaces:

    - eth0 Selected

### Disks:

    - SR: Local Storage
    - Name: {OS_NAME}-{Version}-Disk
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

4. Installation Steps and Notes:

- 4.1 [Ubuntu]

  - 4.1.1 Follow the Ubuntu installation steps, leave most of the settings as default, agree to install `openssh` server.

  - 4.1.2 Profile Configuration:

    - Server Name: ubuntu
    - Name: ubuntu
    - Password: ubuntu
    - Confirm Password: ubuntu

  - 4.1.3 (Optional) Installation will complete, and the VM will reboot, after it reboots, execute following commands:

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

- 4.2 [OpenBSD]

  - 4.2.1 Follow the OpenBSD installation steps, leave most of the settings as default.

  - 4.2.2 Profile Configuration:

    - hostname: bsd
    - root password: bsd

  - 4.2.3 De-select the optional sets, and continue with the installation.
  - 4.2.3 Enter `y` when asked to skip the SHA256.sig verification.
  - 4.2.4 (Optional) Install `xe-guest-utilities`, [this forum post](https://xcp-ng.org/forum/post/23527) has the steps to install `xe-guest-utilities` on OpenBSD.
    ```bash
    pkg_add xe-guest-utilities
    rcctl enable xe-daemon
    rcctl set xe-daemon flags -n
    rcctl start xe-daemon
    ```

  ### Note: If you didn't create a user during the installation, default login is `root` with password `bsd` (if you allowed root login).

- 4.3 [Alpine Linux]

  - 4.3.1 `setup-alpine`, all defaults, make sure you select a disk and `sys`, create a user.
  - 4.3.2 (Optional) Install `xe-guest-utilities`.
    ```bash
    # Enable the community repository in /etc/apk/repositories (uncomment the line using `vi`)
    apk add xe-guest-utilities
    rc-update add xe-guest-utilities
    rc-service xe-guest-utilities start
    ```

6. Reboot the VM, After the VM reboots, get the IP address of the VM, and use `shell/copy_ssh_keys.sh` script to copy your SSH keys to the VM.

   ```bash
   Usage: ./copy_ssh_keys.sh [IP] [USERNAME] [SSH_KEYS_FILEPATH(Optional)]
   Example: ./copy_ssh_keys.sh 192.168.x.x root
   ```

7. Shutdown the VM, and convert it into a template at XOA WebUI > VM > Advanced > Convert to Template.

8. The template is now ready to be used to create new VMs. Edit VM Parameters on `config.env` and use `clone.py` script to create new VMs off the template.

   - Usage: `python3 -m clone`

### References:

- [Create and use custom XCP-ng Ubuntu templates](https://docs.xcp-ng.org/guides/create-use-custom-xcpng-ubuntu-templates/#from-an-iso-file)
- [Setting up SSH Server on AlpineLinux](https://wiki.alpinelinux.org/wiki/Setting_up_a_SSH_server)
- [Setting up a new user on AlpineLinux](https://wiki.alpinelinux.org/wiki/Setting_up_a_new_user)
