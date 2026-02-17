locals {
  public_ips = try(oci_core_public_ip.public_ip[*].ip_address, [])
  instances_details = [
    for idx, i in oci_core_instance.instance : <<-EOT
    ${i.display_name}
    Primary-PublicIP: %{if length(local.public_ips) > idx}${local.public_ips[idx]}%{else}N/A%{endif}
    Primary-PrivateIP: ${i.private_ip}
    EOT
  ]
}

output "instances_summary" {
  description = "Instance summary (name, public/private IP)"
  value       = local.instances_details
}

output "instance_id" {
  description = "Instance OCIDs"
  value       = oci_core_instance.instance[*].id
}

output "private_ip" {
  description = "Private IPs"
  value       = oci_core_instance.instance[*].private_ip
}

output "public_ip" {
  description = "Public IPs"
  value       = local.public_ips
}

output "instance_username" {
  description = "Usernames for instance login (Windows)"
  value       = data.oci_core_instance_credentials.credential[*].username
}

output "instance_password" {
  description = "Passwords for instance login (Windows)"
  value       = data.oci_core_instance_credentials.credential[*].password
  sensitive   = true
}
