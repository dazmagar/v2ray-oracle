# OCI provider identity
variable "tenancy_ocid" {
  type        = string
  description = "Tenancy OCID"
}

variable "user_ocid" {
  type        = string
  description = "OCID of the user used by Terraform"
}

variable "fingerprint" {
  type        = string
  description = "Fingerprint of OCI API private key"
}

variable "private_key_path" {
  type        = string
  description = "Path to OCI API private key"
}

variable "region" {
  type        = string
  description = "OCI region for resources"
}

# General OCI
variable "compartment_ocid" {
  type        = string
  description = "Compartment OCID for all resources"
}

variable "freeform_tags" {
  type        = map(string)
  description = "Freeform tags for resources"
  default     = null
}

variable "defined_tags" {
  type        = map(string)
  description = "Defined tags for resources"
  default     = null
}

# Compute instance (OCI)
variable "instance_ad_number" {
  type        = number
  description = "Availability domain number (1–3). Matches AD-1/2/3 in region"
  default     = 3
}

variable "instance_fd_number" {
  type        = number
  description = "Fault domain (1–3). null = auto"
  default     = null

  validation {
    condition     = var.instance_fd_number == null || (var.instance_fd_number >= 1 && var.instance_fd_number <= 3)
    error_message = "Fault domain must be 1–3 or null"
  }
}

variable "instance_display_name" {
  type        = string
  description = "Display name of the compute instance"
  default     = "v2ray-server"
}

variable "instance_state" {
  type        = string
  description = "Instance state: RUNNING or STOPPED"
  default     = "RUNNING"

  validation {
    condition     = contains(["RUNNING", "STOPPED"], var.instance_state)
    error_message = "Must be RUNNING or STOPPED"
  }
}

variable "shape" {
  type        = string
  description = "Instance shape"
  default     = "VM.Standard.E2.1.Micro"
}

variable "source_ocid" {
  type        = string
  description = "OCID of the boot image (e.g. Ubuntu 24.04)"
}

variable "source_type" {
  type        = string
  description = "Source type for instance (image or bootVolume)"
  default     = "image"
}

variable "ssh_public_keys" {
  type        = string
  description = "Path to SSH public key file or inline key content"
}

variable "public_ip" {
  type        = string
  description = "Public IP: NONE, RESERVED, or EPHEMERAL"
  default     = "RESERVED"

  validation {
    condition     = contains(["NONE", "RESERVED", "EPHEMERAL"], var.public_ip)
    error_message = "Must be NONE, RESERVED, or EPHEMERAL"
  }
}

variable "subnet_ocids" {
  type        = list(string)
  description = "Subnet OCIDs for the instance primary VNIC"
}

variable "boot_volume_backup_policy" {
  type        = string
  description = "Boot volume backup policy: gold, silver, bronze, disabled"
  default     = "disabled"

  validation {
    condition     = contains(["gold", "silver", "bronze", "disabled"], var.boot_volume_backup_policy)
    error_message = "Must be gold, silver, bronze, or disabled"
  }
}

# Provisioning / SSH
variable "user" {
  type        = string
  description = "SSH user for instance access (e.g. ubuntu)"
}

variable "privatekeypath" {
  type        = string
  description = "Path to private SSH key for instance access"
}

# V2Ray / 3x-ui
variable "v2ray_host" {
  type        = string
  description = "V2Ray panel host IP or FQDN (for client links and Caddy)"
}

variable "panel_port" {
  type        = number
  description = "3x-ui panel listen port"
  default     = 2053
}

variable "panel_base_path" {
  type        = string
  description = "3x-ui panel base path (e.g. /xui-abc/). Empty = /panel/"
  default     = ""
}

variable "enable_caddy_tls" {
  type        = bool
  description = "Use Caddy reverse proxy with TLS for panel on 443"
  default     = true
}

variable "caddy_use_internal_tls" {
  type        = bool
  description = "Use Caddy self-signed cert (no Let's Encrypt). Set true if ACME cannot reach host; set false when port 80 is open from internet for LE."
  default     = true
}

variable "proxy_port" {
  type        = number
  description = "Port for VLESS/Reality proxy (Xray). Set inbound port in 3x-ui to this."
  default     = 8443
}

variable "panel_host" {
  type        = string
  description = "Panel host for Caddy: subdomain (e.g. ui) or full FQDN. Empty = panel.<v2ray_host>"
  default     = ""
}

variable "cron_restart_schedule" {
  type        = string
  description = "Cron schedule for 3x-ui container restart"
  default     = "0 3 * * *"
}

variable "backup_path" {
  type        = string
  description = "Local path for 3x-ui panel backup"
  default     = "./modules/backup/xui_backup"
}
