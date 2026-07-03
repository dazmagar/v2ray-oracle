data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_ocid
}

data "oci_core_volume_backup_policies" "default_backup_policies" {}

locals {
  ADs = [for i in data.oci_identity_availability_domains.ads.availability_domains : i.name]
  backup_policies = {
    for i in data.oci_core_volume_backup_policies.default_backup_policies.volume_backup_policies : i.display_name => i.id
  }
}

data "oci_core_subnet" "instance_subnet" {
  count     = length(var.subnet_ocids)
  subnet_id = element(var.subnet_ocids, count.index)
}

data "oci_core_shapes" "current_ad" {
  compartment_id      = var.compartment_ocid
  availability_domain = var.ad_number == null ? element(local.ADs, 0) : element(local.ADs, var.ad_number - 1)
}

locals {
  shapes_config = {
    for i in data.oci_core_shapes.current_ad.shapes : i.name => {
      memory_in_gbs = i.memory_in_gbs
      ocpus         = i.ocpus
    }
  }
  shape_is_flex = length(regexall("^*.Flex", var.shape)) > 0
}

resource "oci_core_instance" "instance" {
  count                = var.instance_count
  availability_domain   = var.ad_number == null ? element(local.ADs, count.index) : element(local.ADs, var.ad_number - 1)
  fault_domain         = var.fd_number == null ? null : "FAULT-DOMAIN-${var.fd_number}"
  compartment_id       = var.compartment_ocid
  display_name         = var.instance_display_name == "" ? "" : var.instance_count != 1 ? "${var.instance_display_name}_${count.index + 1}" : var.instance_display_name
  extended_metadata    = var.extended_metadata
  ipxe_script          = var.ipxe_script
  preserve_boot_volume = var.preserve_boot_volume
  state                = var.instance_state
  shape                = var.shape
  shape_config {
    memory_in_gbs             = local.shape_is_flex && var.instance_flex_memory_in_gbs != null ? var.instance_flex_memory_in_gbs : local.shapes_config[var.shape]["memory_in_gbs"]
    ocpus                     = local.shape_is_flex && var.instance_flex_ocpus != null ? var.instance_flex_ocpus : local.shapes_config[var.shape]["ocpus"]
    baseline_ocpu_utilization = var.baseline_ocpu_utilization
  }

  agent_config {
    are_all_plugins_disabled = false
    is_management_disabled   = false
    is_monitoring_disabled   = false
    plugins_config {
      desired_state = lookup(var.cloud_agent_plugins, "autonomous_linux", "ENABLED")
      name          = "Oracle Autonomous Linux"
    }
    plugins_config {
      desired_state = lookup(var.cloud_agent_plugins, "bastion", "ENABLED")
      name          = "Bastion"
    }
    plugins_config {
      desired_state = lookup(var.cloud_agent_plugins, "block_volume_mgmt", "DISABLED")
      name          = "Block Volume Management"
    }
    plugins_config {
      desired_state = lookup(var.cloud_agent_plugins, "custom_logs", "ENABLED")
      name          = "Custom Logs Monitoring"
    }
    plugins_config {
      desired_state = lookup(var.cloud_agent_plugins, "management", "DISABLED")
      name          = "Management Agent"
    }
    plugins_config {
      desired_state = lookup(var.cloud_agent_plugins, "monitoring", "ENABLED")
      name          = "Compute Instance Monitoring"
    }
    plugins_config {
      desired_state = lookup(var.cloud_agent_plugins, "osms", "ENABLED")
      name          = "OS Management Service Agent"
    }
    plugins_config {
      desired_state = lookup(var.cloud_agent_plugins, "run_command", "ENABLED")
      name          = "Compute Instance Run Command"
    }
    plugins_config {
      desired_state = lookup(var.cloud_agent_plugins, "vulnerability_scanning", "ENABLED")
      name          = "Vulnerability Scanning"
    }
    plugins_config {
      desired_state = lookup(var.cloud_agent_plugins, "java_management_service", "DISABLED")
      name          = "Oracle Java Management Service"
    }
  }

  create_vnic_details {
    assign_public_ip       = false
    display_name           = var.vnic_name == "" ? "" : var.instance_count != 1 ? "${var.vnic_name}_${count.index + 1}" : var.vnic_name
    hostname_label         = var.hostname_label == "" ? "" : var.instance_count != 1 ? "${var.hostname_label}-${count.index + 1}" : var.hostname_label
    private_ip             = element(concat(var.private_ips, [""]), length(var.private_ips) == 0 ? 0 : count.index)
    skip_source_dest_check = var.skip_source_dest_check
    subnet_id              = data.oci_core_subnet.instance_subnet[count.index % length(data.oci_core_subnet.instance_subnet)].id
    nsg_ids                = [oci_core_network_security_group.v2ray.id]
    freeform_tags          = local.merged_freeform_tags
    defined_tags           = var.defined_tags
  }

  metadata = {
    ssh_authorized_keys = file(var.publickeypath)
    user_data           = var.user_data
  }

  source_details {
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
    source_id               = var.source_ocid
    source_type             = var.source_type
  }

  freeform_tags = local.merged_freeform_tags
  defined_tags  = var.defined_tags

  timeouts {
    create = var.instance_timeout
  }

  lifecycle {
    ignore_changes = [
      source_details,
      fault_domain,
      metadata,
    ]
  }
}

data "oci_core_instance_credentials" "credential" {
  count       = var.resource_platform != "linux" ? var.instance_count : 0
  instance_id = oci_core_instance.instance[count.index].id
}

data "oci_core_vnic_attachments" "vnic_attachment" {
  count          = var.instance_count
  compartment_id = var.compartment_ocid
  instance_id    = oci_core_instance.instance[count.index].id
  depends_on     = [oci_core_instance.instance]
}

data "oci_core_private_ips" "private_ips" {
  count   = var.instance_count
  vnic_id = data.oci_core_vnic_attachments.vnic_attachment[count.index].vnic_attachments[0].vnic_id
  depends_on = [oci_core_instance.instance]
}

resource "oci_core_public_ip" "public_ip" {
  count          = var.public_ip == "NONE" ? 0 : var.instance_count
  compartment_id = var.compartment_ocid
  lifetime       = var.public_ip
  display_name   = var.public_ip_display_name != null ? var.public_ip_display_name : oci_core_instance.instance[count.index].display_name
  private_ip_id  = data.oci_core_private_ips.private_ips[count.index].private_ips[0].id
  freeform_tags  = local.merged_freeform_tags
  defined_tags   = var.defined_tags
}
