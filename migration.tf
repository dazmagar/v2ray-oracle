# One-time migration off root-managed subnet/SL (prod safety: do not destroy existing subnet).
removed {
  from = oci_core_subnet.primary

  lifecycle {
    destroy = false
  }
}

removed {
  from = oci_core_security_list.v2ray_sl

  lifecycle {
    destroy = false
  }
}

moved {
  from = oci_core_network_security_group.v2ray
  to   = module.instance.oci_core_network_security_group.v2ray
}
