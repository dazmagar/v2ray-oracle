# V2Ray 3x-ui - Terraform deployment for Oracle Cloud (OCI)

Deploy a V2Ray/Xray VPN server with **3x-ui** web panel on Oracle Cloud Infrastructure.  
Logic mirrors the [GCP version](../v2ray-gcp).

## References

- [3x-ui](https://github.com/MHSanaei/3x-ui)
- [Xray-core](https://github.com/XTLS/Xray-core)

## Features

- Xray server + 3x-ui panel (VMess, VLESS, Trojan, Shadowsocks)
- Docker-based 3x-ui (official image, **pinned tag** via `xui_image` in tfvars)
- Optional Caddy reverse proxy with TLS (panel on 443)
- NSG firewall on primary VNIC (dynamic ports from tfvars)
- Optional backup of 3x-ui DB and config
- Optional cron for container restart

## Prerequisites

- Terraform >= 1.7 (for `removed` / `moved` migration blocks)
- OCI API key (tenancy, user, fingerprint, `private_key_path`)
- Existing VCN and **public** subnet
- SSH key pair for instance access (`publickeypath` / `privatekeypath`)

## Quick start

1. Copy and edit variables:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
2. Set OCI credentials, `compartment_ocid`, `subnet_ocids`, `source_ocid`, SSH paths, `v2ray_host`, and all required VPN variables (see `terraform.tfvars.example`).
3. Initialize and apply:
   ```bash
   terraform init
   terraform apply
   ```
4. Panel URL:
   ```bash
   terraform output panel_url
   ```
   Default login: `admin` / `admin` - change in Panel Settings.

## Configuration

- **v2ray_host** - IP or FQDN of the server (client links and Caddy server name). Point DNS A record to the instance public IP.
- **xui_image** - pinned 3x-ui Docker image tag (required). Example: `ghcr.io/mhsanaei/3x-ui:v3.4.2`. Do not use `:latest`; bump the tag in `terraform.tfvars` when upgrading, then `terraform apply` (re-runs the 3x-ui container via `null_resource.run_3x_ui` trigger).
- **Firewall (NSG):** `firewall_tcp_ports` / `firewall_udp_ports` in `terraform.tfvars`; **`proxy_port` is always merged into TCP**, **`panel_port` is merged when `enable_caddy_tls` is false** (direct panel). With Caddy enabled, `panel_port` is not opened on the NSG (panel only via HTTPS on 443). UDP 51821 is reserved for the peer2weird WireGuard egress peer.
- **caddy_use_internal_tls** - OCI-only: use Caddy self-signed cert (`true`) or Let's Encrypt (`false` when port 80 is reachable from the internet).

## Backup and restore

- Data lives on the instance disk in `/home/<user>/x-ui/` and is lost only when the instance is recreated.
- **Backup module** runs when `instance_id` / `instance_ip` change (e.g. after VM replacement). A routine `terraform apply` with an unchanged VM does **not** re-run backup scripts.
- **Manual backup** without recreating the VM:
  ```bash
  terraform apply -replace="module.backup.null_resource.backup_xui"
  ```
  Copies `/home/<user>/x-ui/` into `backup_path/current/` and `backup_path/<year>/xui.backup.<timestamp>/`.
- **Restore:** If `backup_path/current/` exists when you run `terraform apply` (e.g. after redeploy), the provisioner restores it before starting 3x-ui.

## Migration from Security List + root NSG

If upgrading from an older layout that managed subnet Security List and root-level NSG, `migration.tf` uses `removed` (subnet/SL, no destroy) and `moved` (NSG into `modules/instance`). First apply after upgrade may replace individual NSG rules (dynamic `for_each`); the compute instance should not be replaced if `source_details` is ignored.

## Troubleshooting

- Panel URL: `terraform output panel_url`
- Container: `sudo docker ps -a --filter "name=3x-ui"`
- Logs: `sudo docker logs 3x-ui`
