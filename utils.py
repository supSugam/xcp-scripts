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
