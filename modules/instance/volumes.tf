resource "oci_core_volume_backup_policy_assignment" "boot_volume_backup_policy" {
  count     = var.boot_volume_backup_policy != "disabled" ? var.instance_count : 0
  asset_id  = oci_core_instance.instance[count.index].boot_volume_id
  policy_id = local.backup_policies[var.boot_volume_backup_policy]
}

resource "oci_core_volume" "volume" {
  count               = var.instance_count * length(var.block_storage_sizes_in_gbs)
  availability_domain = oci_core_instance.instance[count.index % var.instance_count].availability_domain
  compartment_id      = var.compartment_ocid
  display_name        = "${oci_core_instance.instance[count.index % var.instance_count].display_name}_volume${floor(count.index / var.instance_count)}"
  size_in_gbs         = element(var.block_storage_sizes_in_gbs, floor(count.index / var.instance_count))
  is_auto_tune_enabled = var.block_storage_enable_autotune
  freeform_tags        = local.merged_freeform_tags
  defined_tags         = var.defined_tags
}

resource "oci_core_volume_attachment" "volume_attachment" {
  count           = var.instance_count * length(var.block_storage_sizes_in_gbs)
  attachment_type = var.attachment_type
  instance_id     = oci_core_instance.instance[count.index % var.instance_count].id
  volume_id       = oci_core_volume.volume[count.index].id
  use_chap        = var.use_chap
}
