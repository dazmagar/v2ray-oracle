variable "user" {
  type        = string
  description = "SSH username for VM instance access"
}

variable "privatekeypath" {
  type        = string
  description = "Path to private SSH key file"
}

variable "instance_ip" {
  type        = string
  description = "Instance public IP"
}

variable "backup_path" {
  type        = string
  description = "Local path for 3x-ui backup (used for restore when backup_path/current exists)"
  default     = ""
}

variable "v2ray_host" {
  type        = string
  description = "V2Ray/Xray panel host IP or FQDN"
}

variable "panel_port" {
  type        = number
  description = "3x-ui panel listen port"
  default     = 2053
}

variable "proxy_port" {
  type        = number
  description = "Xray/VLESS inbound port (e.g. 8443)"
  default     = 8443
}

variable "panel_base_path" {
  type        = string
  description = "3x-ui panel base path (e.g. /xui-xxx/). Empty = default /panel/"
  default     = ""
}

variable "enable_caddy_tls" {
  type        = bool
  description = "Install Caddy as reverse proxy with Let's Encrypt for panel HTTPS"
  default     = true
}

variable "caddy_use_internal_tls" {
  type        = bool
  description = "Use Caddy internal (self-signed) cert instead of Let's Encrypt. Set true if ACME cannot reach the host (e.g. port 80 blocked from internet). Browser will show certificate warning."
  default     = true
}

variable "panel_host" {
  type        = string
  description = "Panel host: subdomain prefix or full FQDN. Empty = panel.<v2ray_host>"
  default     = ""
}

variable "cron_restart_schedule" {
  type        = string
  description = "Cron schedule for 3x-ui container restart"
}

variable "xui_image" {
  type        = string
  description = "Pinned 3x-ui Docker image (tag, not latest)"
}
