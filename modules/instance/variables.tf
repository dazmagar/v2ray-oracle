variable "compartment_ocid" {
  type        = string
  description = "OCID of the compartment"
}

variable "instance_timeout" {
  type        = string
  description = "Timeout for instance create"
  default     = "25m"
}

variable "freeform_tags" {
  type        = map(string)
  default     = null
}

variable "defined_tags" {
  type        = map(string)
  default     = null
}

locals {
  default_freeform_tags = {
    terraformed = "Please do not edit manually"
    module      = "v2ray-oracle-instance"
  }
  merged_freeform_tags = merge(local.default_freeform_tags, var.freeform_tags != null ? var.freeform_tags : {})
}

variable "ad_number" {
  type        = number
  description = "Availability domain number (1-based). null = use first AD"
  default     = null
}

variable "fd_number" {
  type        = number
  description = "Fault domain (1-3). null = auto"
  default     = null
  validation {
    condition     = var.fd_number == null || (var.fd_number >= 1 && var.fd_number <= 3)
    error_message = "Fault domain must be 1-3 or null"
  }
}

variable "instance_count" {
  type        = number
  default     = 1
}

variable "instance_display_name" {
  type        = string
  default     = ""
}

variable "instance_flex_memory_in_gbs" {
  type    = number
  default = null
}

variable "instance_flex_ocpus" {
  type    = number
  default = null
}

variable "instance_state" {
  type        = string
  default     = "RUNNING"
  validation {
    condition     = contains(["RUNNING", "STOPPED"], var.instance_state)
    error_message = "Must be RUNNING or STOPPED"
  }
}

variable "shape" {
  type        = string
  default     = null
}

variable "cloud_agent_plugins" {
  type        = map(string)
  default = {
    autonomous_linux       = "DISABLED"
    bastion                = "DISABLED"
    block_volume_mgmt      = "DISABLED"
    custom_logs            = "DISABLED"
    management             = "DISABLED"
    monitoring             = "ENABLED"
    osms                   = "DISABLED"
    run_command            = "DISABLED"
    vulnerability_scanning = "DISABLED"
    java_management_service = "DISABLED"
  }
}

variable "baseline_ocpu_utilization" {
  type        = string
  default     = "BASELINE_1_1"
  validation {
    condition     = contains(["BASELINE_1_8", "BASELINE_1_2", "BASELINE_1_1"], var.baseline_ocpu_utilization)
    error_message = "Must be BASELINE_1_8, BASELINE_1_2, or BASELINE_1_1"
  }
}

variable "source_ocid" {
  type = string
}

variable "source_type" {
  type    = string
  default = "image"
}

variable "extended_metadata" {
  type    = map(any)
  default = {}
}

variable "resource_platform" {
  type    = string
  default = "linux"
}

variable "ssh_authorized_keys" {
  type    = string
  default = null
}

variable "ssh_public_keys" {
  type    = string
  default = null
}

variable "user_data" {
  type    = string
  default = null
}

variable "hostname_label" {
  type    = string
  default = ""
}

variable "ipxe_script" {
  type    = string
  default = null
}

variable "private_ips" {
  type    = list(string)
  default = []
}

variable "public_ip" {
  type        = string
  default     = "NONE"
  validation {
    condition     = contains(["NONE", "RESERVED", "EPHEMERAL"], var.public_ip)
    error_message = "Must be NONE, RESERVED, or EPHEMERAL"
  }
}

variable "public_ip_display_name" {
  type    = string
  default = null
}

variable "skip_source_dest_check" {
  type    = bool
  default = false
}

variable "subnet_ocids" {
  type = list(string)
}

variable "vnic_name" {
  type    = string
  default = ""
}

variable "primary_vnic_nsg_ids" {
  type    = list(string)
  default = null
}

variable "attachment_type" {
  type    = string
  default = "paravirtualized"
}

variable "block_storage_sizes_in_gbs" {
  type    = list(number)
  default = []
}

variable "block_storage_enable_autotune" {
  type    = bool
  default = true
}

variable "boot_volume_backup_policy" {
  type        = string
  default     = "disabled"
  validation {
    condition     = contains(["gold", "silver", "bronze", "disabled"], var.boot_volume_backup_policy)
    error_message = "Must be gold, silver, bronze, or disabled"
  }
}

variable "boot_volume_size_in_gbs" {
  type    = number
  default = 50
}

variable "preserve_boot_volume" {
  type    = bool
  default = false
}

variable "use_chap" {
  type    = bool
  default = false
}
