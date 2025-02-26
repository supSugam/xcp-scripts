import os
import time
import argparse
from dotenv import load_dotenv
import XenAPI
from config import CONFIG
from utils import get_template_ref

# Load envs
load_dotenv("config.env")
XOA_VM_IP = os.getenv("HOST_IP")
XOA_LOGIN_USERNAME = os.getenv("HOST_USERNAME")
XOA_LOGIN_PASSWORD = os.getenv("HOST_PASSWORD")


def main():

    # TODO: Way to grab custom templates from xoa instead of config file
    templates = CONFIG.get("templates", {})
    if not templates:
        raise Exception("No templates found in the config file")

    parser = argparse.ArgumentParser(description="Clone a VM from a template")
    parser.add_argument(
        "--template_name",
        type=str,
        required=True,
        help="Name of the template to clone",
    )

    parser.add_argument(
        "--vm_name",
        type=str,
        required=False,
        help="Name of the VM to create",
    )

    parser.add_argument(
        "--vm_description",
        type=str,
        required=False,
        help="Description of the VM",
    )

    args = parser.parse_args()

    if not templates.get(args.template_name):
        raise Exception(
            f"\n\nTemplate {args.template_name} not found in the templates list\nAvailable templates: {list(templates.keys())}"
        )

    template = templates[args.template_name]

    VM_NAME = args.vm_name or f"{template['name']}-cloned"
    VM_DESCRIPTION = (
        args.vm_description or f"Cloned from {template['name']} using clone.py"
    )

    try:
        session = XenAPI.Session(
            f"http://{XOA_VM_IP}",
            ignore_ssl=True,
        )
        session.login_with_password(XOA_LOGIN_USERNAME, XOA_LOGIN_PASSWORD)
        print("Successfully connected to XOA")

        template_ref = get_template_ref(session, template["name"])
        if template_ref is None:
            raise Exception("Template not found")

        vm = session.xenapi.VM.clone(template_ref, VM_NAME)
        session.xenapi.VM.provision(vm)
        session.xenapi.VM.set_is_a_template(vm, False)
        session.xenapi.VM.set_name_label(vm, VM_NAME)
        session.xenapi.VM.set_name_description(vm, VM_DESCRIPTION)
        session.xenapi.VM.set_other_config(vm, {"base_template_name": template["name"]})
        # Start the VM
        session.xenapi.VM.start(vm, False, True)
        print("VM Cloned Successfully")

        # Grab IP address (Need a better way to wait for the VM to boot up completely first)
        ip_address = None
        start = time.time()
        while ip_address is None and time.time() - start < 60 * 2:
            try:
                guest_metrics_ref = session.xenapi.VM.get_guest_metrics(vm)
                if guest_metrics_ref and not guest_metrics_ref.endswith("NULL"):
                    networks = session.xenapi.VM_guest_metrics.get_networks(
                        guest_metrics_ref
                    )
                    ip_address = networks.get("0/ip")
                    if ip_address:
                        print(
                            f"VM IP Address: {ip_address}, ssh into this IP to access the VM"
                        )
                        break
                else:
                    print(
                        "No IP address found, Make sure xe-guest-utilities is installed"
                    )
            except XenAPI.Failure as e:
                print(f"Error retrieving IP address: {e}")
                time.sleep(5)
        else:
            print("Failed to retrieve IP address within the timeout period")

    except Exception as e:
        raise e
    finally:
        session.logout()


if __name__ == "__main__":
    main()
