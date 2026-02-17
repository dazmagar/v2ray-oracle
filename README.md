# V2Ray 3x-ui – Terraform deployment for Oracle Cloud (OCI)

Deploy a V2Ray/Xray VPN server with **3x-ui** web panel on Oracle Cloud Infrastructure.  
Logic mirrors the [GCP version](../v2ray-gcp); OCI wiring follows the [amnezia-wg-easy-oracle](../amnezia-wg-easy-oracle) style.

## References

- [3x-ui](https://github.com/MHSanaei/3x-ui)
- [Xray-core](https://github.com/XTLS/Xray-core)

## Features

- Xray server + 3x-ui panel (VMess, VLESS, Trojan, Shadowsocks)
- Docker-based 3x-ui (official image)
- Optional Caddy reverse proxy with TLS (panel on 443)
- Optional backup of 3x-ui DB and config
- Optional cron for container restart

## Prerequisites

- Terraform >= 1.0
- OCI CLI config or API key (tenancy, user, key, fingerprint)
- Existing VCN and **public** subnet (or subnet with reserved/ephemeral public IP)
- SSH key pair for instance access

## Network (Security List / NSG)

Open on the instance subnet (or NSG attached to the primary VNIC):

- **TCP:** 22 (SSH), 80 (HTTP for Let’s Encrypt if Caddy is used), 443 (Caddy/panel or proxy), `proxy_port` (Xray), 37883 (3x-ui API if used)
- **UDP:** 443 (Xray)

If Caddy is disabled, open `panel_port` (e.g. 2053) instead of 443 for the panel.

## Quick start

1. Copy and edit variables:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
2. Set OCI credentials, `compartment_ocid`, `subnet_ocids`, `source_ocid` (Ubuntu 24.04 image OCID), SSH paths, and `v2ray_host`.
3. **First-time only:** import the existing subnet so Terraform can attach the v2ray Security List (opens 22, 80, 443, panel/proxy ports at subnet level):
   ```bash
   terraform init
   terraform import oci_core_subnet.primary "<subnet_ocid>"
   ```
   Use the same OCID as in `subnet_ocids[0]` from your tfvars.
4. Apply:
   ```bash
   terraform apply
   ```
5. Panel URL:
   ```bash
   terraform output panel_url
   ```
   Default login: `admin` / `admin` — change in Panel Settings.

## Configuration

- **v2ray_host** – IP or FQDN of the server (client links and Caddy server name). Point DNS A record to the instance public IP.
- **proxy_port** – Set the VLESS/Reality inbound port in 3x-ui to this value (panel can be on 443 via Caddy).

## Backup and restore

- Data lives on the instance disk in `/home/<user>/x-ui/` and is lost only when the instance is recreated.
- **Backup (before destroy/recreate):**
  ```bash
  terraform apply -target="module.backup"
  ```
  Copies `/home/<user>/x-ui/` into `backup_path/current/` and `backup_path/<year>/xui.backup.<timestamp>/`.
- **Restore:** If `backup_path/current/` exists when you run `terraform apply` (e.g. after a new deploy), the provisioner restores it to the new instance before starting 3x-ui.

## Troubleshooting

- Panel URL: `terraform output panel_url`
- Container: `sudo docker ps -a --filter "name=3x-ui"`
- Logs: `sudo docker logs 3x-ui`
