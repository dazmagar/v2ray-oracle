# Run from the PC where the browser does not open the panel.
# Checks DNS, TCP 80/443 to instance IP.
param(
    [string] $Hostname = "v2ray.eu.fra.dazmagar.com",
    [string] $IP       = "141.147.26.68"
)

Write-Host "=== DNS ===" -ForegroundColor Cyan
$dns = Resolve-DnsName -Name $Hostname -Type A -ErrorAction SilentlyContinue
if ($dns) { Write-Host "$Hostname -> $($dns.IPAddress)" } else { Write-Host "FAIL: could not resolve $Hostname" }

Write-Host "`n=== TCP 80 (HTTP) ===" -ForegroundColor Cyan
$t80 = Test-NetConnection -ComputerName $IP -Port 80 -WarningAction SilentlyContinue
Write-Host "TcpTestSucceeded: $($t80.TcpTestSucceeded)"

Write-Host "`n=== TCP 443 (HTTPS) ===" -ForegroundColor Cyan
$t443 = Test-NetConnection -ComputerName $IP -Port 443 -WarningAction SilentlyContinue
Write-Host "TcpTestSucceeded: $($t443.TcpTestSucceeded)"

if (-not $t443.TcpTestSucceeded) {
    Write-Host "`n443 is not reachable from this PC. Panel will not load. Check: OCI Security List, NSG, instance ufw, or local/office firewall." -ForegroundColor Yellow
}
