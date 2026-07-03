resource "oci_core_network_security_group" "v2ray" {
  compartment_id = var.compartment_ocid
  vcn_id         = data.oci_core_subnet.instance_subnet[0].vcn_id
  display_name   = "v2ray-nsg"
}

resource "oci_core_network_security_group_security_rule" "ingress_tcp" {
  for_each = toset(var.firewall_tcp_ports)

  network_security_group_id = oci_core_network_security_group.v2ray.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = "0.0.0.0/0"

  tcp_options {
    destination_port_range {
      min = tonumber(each.value)
      max = tonumber(each.value)
    }
  }
}

resource "oci_core_network_security_group_security_rule" "ingress_udp" {
  for_each = toset(var.firewall_udp_ports)

  network_security_group_id = oci_core_network_security_group.v2ray.id
  direction                 = "INGRESS"
  protocol                  = "17"
  source                    = "0.0.0.0/0"

  udp_options {
    destination_port_range {
      min = tonumber(each.value)
      max = tonumber(each.value)
    }
  }
}

resource "oci_core_network_security_group_security_rule" "egress_all" {
  network_security_group_id = oci_core_network_security_group.v2ray.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
}
