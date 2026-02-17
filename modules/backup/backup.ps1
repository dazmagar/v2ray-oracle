# Cross-platform backup script for Windows PowerShell (3x-ui)

param(
  [string]$PRIVATE_KEY_PATH,
  [string]$USER,
  [string]$INSTANCE_IP,
  [string]$BACKUP_PATH
)

$ErrorActionPreference = "Continue"

if (-not $PRIVATE_KEY_PATH) { $PRIVATE_KEY_PATH = $env:PRIVATE_KEY_PATH }
if (-not $USER) { $USER = $env:USER }
if (-not $INSTANCE_IP) { $INSTANCE_IP = $env:INSTANCE_IP }
if (-not $BACKUP_PATH) { $BACKUP_PATH = $env:BACKUP_PATH }

if (-not $PRIVATE_KEY_PATH -or -not $USER -or -not $INSTANCE_IP -or -not $BACKUP_PATH) {
  Write-Error "Error: Required parameters not set"
  exit 1
}

$sshPath = (Get-Command ssh -ErrorAction SilentlyContinue).Source
if (-not $sshPath) {
  $sshPath = "C:\Windows\System32\OpenSSH\ssh.exe"
  if (-not (Test-Path $sshPath)) {
    Write-Error "ssh.exe not found"
    exit 1
  }
}

$scpPath = (Get-Command scp -ErrorAction SilentlyContinue).Source
if (-not $scpPath) {
  $scpPath = "C:\Windows\System32\OpenSSH\scp.exe"
}

$backupDir = $BACKUP_PATH
if (-not (Test-Path $backupDir)) {
  New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$year = Get-Date -Format "yyyy"
$yearDir = Join-Path $backupDir $year
$remoteXui = "/home/$USER/x-ui"
$currentPath = Join-Path $backupDir "current"

Write-Host "Backup directory: $backupDir"
Write-Host "Starting 3x-ui backup at $timestamp"

New-Item -ItemType Directory -Force -Path $yearDir | Out-Null

$testResult = & $sshPath -i $PRIVATE_KEY_PATH -o StrictHostKeyChecking=no -o UserKnownHostsFile=NUL "$USER@$INSTANCE_IP" "test -d $remoteXui" 2>&1
if ($LASTEXITCODE -eq 0) {
  if (Test-Path $currentPath) { Remove-Item -Recurse -Force $currentPath }
  & $scpPath -i $PRIVATE_KEY_PATH -o StrictHostKeyChecking=no -o UserKnownHostsFile=NUL -r "$USER@${INSTANCE_IP}:${remoteXui}/" "${backupDir}/current/" 2>&1
  if (Test-Path $currentPath) {
    Copy-Item -Path $currentPath -Destination (Join-Path $yearDir "xui.backup.$timestamp") -Recurse
    Write-Host "3x-ui backup saved to $yearDir/xui.backup.$timestamp"
  }
} else {
  Write-Warning "Remote path $remoteXui not found or not accessible"
}

Write-Host "Backup completed"
