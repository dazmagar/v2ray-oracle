# Restore 3x-ui backup from local backup_path/current to the instance.

param(
  [string]$PRIVATE_KEY_PATH,
  [string]$USER,
  [string]$INSTANCE_IP,
  [string]$BACKUP_PATH
)

$ErrorActionPreference = "Stop"
if (-not $PRIVATE_KEY_PATH) { $PRIVATE_KEY_PATH = $env:PRIVATE_KEY_PATH }
if (-not $USER) { $USER = $env:USER }
if (-not $INSTANCE_IP) { $INSTANCE_IP = $env:INSTANCE_IP }
if (-not $BACKUP_PATH) { $BACKUP_PATH = $env:BACKUP_PATH }

if (-not $PRIVATE_KEY_PATH -or -not $USER -or -not $INSTANCE_IP -or -not $BACKUP_PATH) {
  Write-Error "Required parameters not set"
  exit 1
}

$currentPath = Join-Path $BACKUP_PATH "current"
if (-not (Test-Path $currentPath) -or -not (Get-ChildItem $currentPath -ErrorAction SilentlyContinue)) {
  Write-Host "No backup to restore (missing or empty $currentPath); skipping restore"
  exit 0
}

$sshPath = (Get-Command ssh -ErrorAction SilentlyContinue).Source
if (-not $sshPath) { $sshPath = "C:\Windows\System32\OpenSSH\ssh.exe" }
$scpPath = (Get-Command scp -ErrorAction SilentlyContinue).Source
if (-not $scpPath) { $scpPath = "C:\Windows\System32\OpenSSH\scp.exe" }

$remoteXui = "/home/$USER/x-ui"
Write-Host "Restoring 3x-ui backup from $currentPath to $USER@$INSTANCE_IP`:${remoteXui}"
& $sshPath -i $PRIVATE_KEY_PATH -o StrictHostKeyChecking=no -o UserKnownHostsFile=NUL "$USER@${INSTANCE_IP}" "mkdir -p $remoteXui; sudo chown -R $USER`:$USER $remoteXui"
$scpArgs = @("-i", $PRIVATE_KEY_PATH, "-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=NUL", "-r", "$currentPath\*", "${USER}@${INSTANCE_IP}:${remoteXui}/")
& $scpPath @scpArgs
Write-Host "Restore completed"
