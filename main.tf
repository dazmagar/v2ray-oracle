data "oci_core_subnet" "primary_data" {
  subnet_id = var.subnet_ocids[0]
}

resource "oci_core_security_list" "v2ray_sl" {
  compartment_id = var.compartment_ocid
  vcn_id         = data.oci_core_subnet.primary_data.vcn_id
  display_name   = "v2ray-sl"

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 80
      max = 80
    }
  }
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 443
      max = 443
    }
  }
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = var.panel_port
      max = var.panel_port
    }
  }
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = var.proxy_port
      max = var.proxy_port
    }
  }
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 37883
      max = 37883
    }
  }
  ingress_security_rules {
    protocol = "17"
    source   = "0.0.0.0/0"
    udp_options {
      min = 443
      max = 443
    }
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}

resource "oci_core_subnet" "primary" {
  compartment_id    = data.oci_core_subnet.primary_data.compartment_id
  vcn_id            = data.oci_core_subnet.primary_data.vcn_id
  cidr_block        = data.oci_core_subnet.primary_data.cidr_block
  availability_domain = data.oci_core_subnet.primary_data.availability_domain
  display_name      = data.oci_core_subnet.primary_data.display_name
  security_list_ids = [oci_core_security_list.v2ray_sl.id]
  route_table_id    = data.oci_core_subnet.primary_data.route_table_id
  dhcp_options_id   = data.oci_core_subnet.primary_data.dhcp_options_id
  freeform_tags     = data.oci_core_subnet.primary_data.freeform_tags
  defined_tags      = data.oci_core_subnet.primary_data.defined_tags
  prohibit_public_ip_on_vnic = data.oci_core_subnet.primary_data.prohibit_public_ip_on_vnic
}

resource "oci_core_network_security_group" "v2ray" {
  compartment_id = var.compartment_ocid
  vcn_id         = data.oci_core_subnet.primary_data.vcn_id
  display_name   = "v2ray-nsg"
}

resource "oci_core_network_security_group_security_rule" "ingress_ssh" {
  network_security_group_id = oci_core_network_security_group.v2ray.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source                    = "0.0.0.0/0"

  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}

resource "oci_core_network_security_group_security_rule" "ingress_http" {
  network_security_group_id = oci_core_network_security_group.v2ray.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = "0.0.0.0/0"

  tcp_options {
    destination_port_range {
      min = 80
      max = 80
    }
  }
}

resource "oci_core_network_security_group_security_rule" "ingress_https" {
  network_security_group_id = oci_core_network_security_group.v2ray.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = "0.0.0.0/0"

  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "ingress_panel" {
  network_security_group_id = oci_core_network_security_group.v2ray.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = "0.0.0.0/0"

  tcp_options {
    destination_port_range {
      min = var.panel_port
      max = var.panel_port
    }
  }
}

resource "oci_core_network_security_group_security_rule" "ingress_proxy" {
  network_security_group_id = oci_core_network_security_group.v2ray.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = "0.0.0.0/0"

  tcp_options {
    destination_port_range {
      min = var.proxy_port
      max = var.proxy_port
    }
  }
}

resource "oci_core_network_security_group_security_rule" "ingress_xui_api" {
  network_security_group_id = oci_core_network_security_group.v2ray.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = "0.0.0.0/0"

  tcp_options {
    destination_port_range {
      min = 37883
      max = 37883
    }
  }
}

resource "oci_core_network_security_group_security_rule" "ingress_udp_443" {
  network_security_group_id = oci_core_network_security_group.v2ray.id
  direction                 = "INGRESS"
  protocol                  = "17" # UDP
  source                    = "0.0.0.0/0"

  udp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "egress_all" {
  network_security_group_id = oci_core_network_security_group.v2ray.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
}

module "instance" {
  source = "./modules/instance"

  compartment_ocid = var.compartment_ocid
  freeform_tags    = var.freeform_tags
  defined_tags     = var.defined_tags

  ad_number                   = var.instance_ad_number
  fd_number                   = var.instance_fd_number
  instance_count              = 1
  instance_display_name       = var.instance_display_name
  instance_state              = var.instance_state
  shape                       = var.shape
  source_ocid                 = var.source_ocid
  source_type                 = var.source_type
  instance_flex_memory_in_gbs = 1
  instance_flex_ocpus         = 1

  ssh_public_keys = file(var.ssh_public_keys)
  user_data       = null

  public_ip    = var.public_ip
  subnet_ocids = [oci_core_subnet.primary.id]

  boot_volume_backup_policy  = var.boot_volume_backup_policy
  block_storage_sizes_in_gbs = []
  preserve_boot_volume       = false

  primary_vnic_nsg_ids = [oci_core_network_security_group.v2ray.id]
}

# Run before instance recreation: terraform apply -target="module.backup"
module "backup" {
  source          = "./modules/backup"
  instance_id     = module.instance.instance_id[0]
  instance_ip     = module.instance.public_ip[0]
  user           = var.user
  privatekeypath = var.privatekeypath
  backup_path    = var.backup_path
}

module "provisioner" {
  depends_on = [module.instance, module.backup]

  source         = "./modules/provisioner"
  instance_ip    = module.instance.public_ip[0]
  user          = var.user
  privatekeypath = var.privatekeypath
  backup_path   = var.backup_path

  v2ray_host             = var.v2ray_host
  panel_port             = var.panel_port
  proxy_port             = var.proxy_port
  panel_base_path       = var.panel_base_path
  enable_caddy_tls      = var.enable_caddy_tls
  caddy_use_internal_tls = var.caddy_use_internal_tls
  panel_host            = var.panel_host
  cron_restart_schedule = var.cron_restart_schedule
}
