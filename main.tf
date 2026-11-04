locals {
  firewall_tcp_ports = distinct(concat(
    [for p in var.firewall_tcp_ports : tostring(p)],
    [tostring(var.proxy_port)],
    var.enable_caddy_tls ? [] : [tostring(var.panel_port)],
  ))
  firewall_udp_ports = distinct([for p in concat(var.firewall_udp_ports, [var.p2w_wireguard_port]) : tostring(p)])
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

  publickeypath = var.publickeypath
  user_data     = null

  public_ip    = var.public_ip
  subnet_ocids = var.subnet_ocids

  boot_volume_backup_policy  = var.boot_volume_backup_policy
  block_storage_sizes_in_gbs = []
  preserve_boot_volume       = false

  firewall_tcp_ports = local.firewall_tcp_ports
  firewall_udp_ports = local.firewall_udp_ports
}

# On-demand backup while VM unchanged: terraform apply -replace="module.backup.null_resource.backup_xui"
module "backup" {
  source         = "./modules/backup"
  instance_id    = module.instance.instance_id[0]
  instance_ip    = module.instance.public_ip[0]
  user           = var.user
  privatekeypath = var.privatekeypath
  backup_path    = var.backup_path
}

module "provisioner" {
  depends_on = [module.instance, module.backup]

  source         = "./modules/provisioner"
  instance_ip    = module.instance.public_ip[0]
  user           = var.user
  privatekeypath = var.privatekeypath
  backup_path    = var.backup_path

  v2ray_host             = var.v2ray_host
  panel_port             = var.panel_port
  proxy_port             = var.proxy_port
  panel_base_path        = var.panel_base_path
  enable_caddy_tls       = var.enable_caddy_tls
  caddy_use_internal_tls = var.caddy_use_internal_tls
  panel_host             = var.panel_host
  cron_restart_schedule  = var.cron_restart_schedule
  xui_image              = var.xui_image
}
