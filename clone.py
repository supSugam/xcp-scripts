import XenAPI
from dotenv import load_dotenv
import os
import random

load_dotenv("config.env")


def get_template_ref(session, template_name):
    templates = session.xenapi.VM.get_all_records()
    for template in templates:
        if session.xenapi.VM.get_is_a_template(template):
            name_label = session.xenapi.VM.get_name_label(template)
            if name_label == template_name:
                return template
    return None


def get_network_ref(session, network_name):
    networks = session.xenapi.network.get_all_records()
    for network in networks:
        name_label = session.xenapi.network.get_name_label(network)
        if name_label == network_name:
            return network
    return None


def main():
    XOA_VM_IP = os.getenv("HOST_IP")
    XOA_LOGIN_USERNAME = os.getenv("HOST_USERNAME")
    XOA_LOGIN_PASSWORD = os.getenv("HOST_PASSWORD")
    try:
        session = XenAPI.Session(
            f"http://{XOA_VM_IP}",
            ignore_ssl=True,
        )
        session.login_with_password(XOA_LOGIN_USERNAME, XOA_LOGIN_PASSWORD)
        print("Successfully connected to XOA")

        template_ref = get_template_ref(session, os.getenv("TEMPLATE_NAME"))
        # network_ref = get_network_ref(session, os.getenv("NETWORK_NAME"))
        if template_ref is None:
            raise Exception("Template not found")
        # if network_ref is None:
        #     raise Exception("Network not found")

        vm = session.xenapi.VM.clone(template_ref, os.getenv("VM_NAME"))
        session.xenapi.VM.provision(vm)
        session.xenapi.VM.set_is_a_template(vm, False)
        # session.xenapi.VM.set_name_label(vm, os.getenv("VM_NAME"))
        session.xenapi.VM.set_name_label(vm, "Ubuntu Test")
        session.xenapi.VM.set_name_description(vm, os.getenv("VM_DESCRIPTION"))
        session.xenapi.VM.set_other_config(
            vm, {"base_template_name": os.getenv("TEMPLATE_NAME")}
        )
        # Start the VM
        session.xenapi.VM.start(vm, False, True)
        print("VM created successfully")

    except Exception as e:
        raise e
    finally:
        session.logout()


if __name__ == "__main__":
    main()
