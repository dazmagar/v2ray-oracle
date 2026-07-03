# Upload install-caddy.sh and configure Caddy (OpenSSH local-exec; Windows).

param(
  [string]$PRIVATE_KEY_PATH,
  [string]$USER,
  [string]$INSTANCE_IP,
  [string]$V2RAY_HOST,
  [string]$PANEL_PORT,
  [string]$CADDY_USE_INTERNAL_TLS
)

$ErrorActionPreference = "Stop"

if (-not $PRIVATE_KEY_PATH) { $PRIVATE_KEY_PATH = $env:PRIVATE_KEY_PATH }
if (-not $USER) { $USER = $env:USER }
if (-not $INSTANCE_IP) { $INSTANCE_IP = $env:INSTANCE_IP }
if (-not $V2RAY_HOST) { $V2RAY_HOST = $env:V2RAY_HOST }
if (-not $PANEL_PORT) { $PANEL_PORT = $env:PANEL_PORT }
if ($null -eq $CADDY_USE_INTERNAL_TLS -or $CADDY_USE_INTERNAL_TLS -eq "") {
  $CADDY_USE_INTERNAL_TLS = $env:CADDY_USE_INTERNAL_TLS
}
if ($null -eq $CADDY_USE_INTERNAL_TLS -or $CADDY_USE_INTERNAL_TLS -eq "") {
  $CADDY_USE_INTERNAL_TLS = "false"
}

if (-not $PRIVATE_KEY_PATH -or -not $USER -or -not $INSTANCE_IP -or -not $V2RAY_HOST) {
  Write-Error "Required parameters not set"
  exit 1
}

function Escape-BashSq([string]$Value) {
  return $Value.Replace("'", "'\''")
}

$sshPath = (Get-Command ssh -ErrorAction SilentlyContinue).Source
if (-not $sshPath) { $sshPath = "C:\Windows\System32\OpenSSH\ssh.exe" }
$scpPath = (Get-Command scp -ErrorAction SilentlyContinue).Source
if (-not $scpPath) { $scpPath = "C:\Windows\System32\OpenSSH\scp.exe" }

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$localScript = Join-Path $scriptDir "install-caddy.sh"
$sshTarget = "$USER@${INSTANCE_IP}"
$sshCommon = @("-i", $PRIVATE_KEY_PATH, "-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=NUL")

& $scpPath @sshCommon $localScript "${sshTarget}:/tmp/install-caddy.sh"

$vh = Escape-BashSq $V2RAY_HOST
$remote = "chmod +x /tmp/install-caddy.sh && bash /tmp/install-caddy.sh '${vh}' ${PANEL_PORT} ${CADDY_USE_INTERNAL_TLS} 2>&1 | tee /tmp/caddy-install.log || { echo 'Caddy install failed' >&2; exit 1; }"

& $sshPath @sshCommon $sshTarget $remote
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
