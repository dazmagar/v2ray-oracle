# Disable host ufw/iptables; OCI NSG handles filtering (OpenSSH local-exec; Windows).

param(
  [string]$PRIVATE_KEY_PATH,
  [string]$USER,
  [string]$INSTANCE_IP
)

$ErrorActionPreference = "Stop"

if (-not $PRIVATE_KEY_PATH) { $PRIVATE_KEY_PATH = $env:PRIVATE_KEY_PATH }
if (-not $USER) { $USER = $env:USER }
if (-not $INSTANCE_IP) { $INSTANCE_IP = $env:INSTANCE_IP }

if (-not $PRIVATE_KEY_PATH -or -not $USER -or -not $INSTANCE_IP) {
  Write-Error "Required parameters not set (PRIVATE_KEY_PATH, USER, INSTANCE_IP)"
  exit 1
}

$sshPath = (Get-Command ssh -ErrorAction SilentlyContinue).Source
if (-not $sshPath) { $sshPath = "C:\Windows\System32\OpenSSH\ssh.exe" }

$sshTarget = "$USER@${INSTANCE_IP}"
$sshCommon = @("-i", $PRIVATE_KEY_PATH, "-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=NUL")

$remote = @"
set -e
if command -v ufw &>/dev/null || [ -x /usr/sbin/ufw ]; then
  sudo /usr/sbin/ufw disable 2>/dev/null || true
  echo 'ufw disabled'
fi
sudo iptables -P INPUT ACCEPT 2>/dev/null || true
sudo iptables -P FORWARD ACCEPT 2>/dev/null || true
sudo iptables -F INPUT 2>/dev/null || true
sudo iptables -F FORWARD 2>/dev/null || true
echo 'Host firewall off; OCI NSG only'
"@

& $sshPath @sshCommon $sshTarget $remote
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
