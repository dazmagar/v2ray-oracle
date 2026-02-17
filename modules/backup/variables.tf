variable "instance_id" {
  type        = string
  description = "Compute instance OCID"
}

variable "instance_ip" {
  type        = string
  description = "Instance public IP"
}

variable "user" {
  type        = string
  description = "SSH user"
}

variable "privatekeypath" {
  type        = string
  description = "Path to private SSH key"
}

variable "backup_path" {
  type        = string
  description = "Local path for 3x-ui backup directory"
  default     = "./modules/backup/xui_backup"
}
