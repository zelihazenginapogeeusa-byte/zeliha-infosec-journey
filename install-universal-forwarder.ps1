<#
.SYNOPSIS
    Sample script that automates installing the Splunk Universal Forwarder on
    the Windows 10 endpoint and pointing it at the Splunk SIEM server.

.DESCRIPTION
    Silently installs the Splunk Universal Forwarder, then copies this repo's
    configs/inputs.conf and configs/outputs.conf into the right folder and
    restarts the service.

.NOTES
    Usage (elevated PowerShell):
      .\install-universal-forwarder.ps1 `
          -MsiPath "C:\Downloads\splunkforwarder-x64.msi" `
          -SplunkServerIp "192.168.56.101"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$MsiPath,

    [Parameter(Mandatory=$true)]
    [string]$SplunkServerIp,

    [string]$SplunkHome = "C:\Program Files\SplunkUniversalForwarder",
    [string]$AdminUser  = "admin",
    [string]$AdminPass  = "changeme123"
)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as Administrator."
    exit 1
}

Write-Host "[1/4] Installing the Splunk Universal Forwarder..."
Start-Process msiexec.exe -ArgumentList "/i `"$MsiPath`" AGREETOLICENSE=Yes SPLUNKUSERNAME=$AdminUser SPLUNKPASSWORD=$AdminPass /quiet" -Wait

Write-Host "[2/4] Configuring inputs.conf and outputs.conf..."
$localDir = Join-Path $SplunkHome "etc\system\local"
New-Item -ItemType Directory -Force -Path $localDir | Out-Null

$inputsConf = @"
[WinEventLog://Security]
disabled = 0
index = windows

[WinEventLog://System]
disabled = 0
index = windows

[WinEventLog://Application]
disabled = 0
index = windows

[WinEventLog://Microsoft-Windows-Sysmon/Operational]
disabled = 0
index = sysmon
renderXml = 1
source = XmlWinEventLog:Microsoft-Windows-Sysmon/Operational
"@
Set-Content -Path (Join-Path $localDir "inputs.conf") -Value $inputsConf -Encoding ASCII

$outputsConf = @"
[tcpout]
defaultGroup = splunk_server

[tcpout:splunk_server]
server = ${SplunkServerIp}:9997
sslVerifyServerCert = false
compressed = true
"@
Set-Content -Path (Join-Path $localDir "outputs.conf") -Value $outputsConf -Encoding ASCII

Write-Host "[3/4] Restarting the Splunk Universal Forwarder service..."
$splunkExe = Join-Path $SplunkHome "bin\splunk.exe"
& $splunkExe restart

Write-Host "[4/4] Installation complete."
Write-Host "To verify, run this query on the Splunk SIEM server: host=$env:COMPUTERNAME"
