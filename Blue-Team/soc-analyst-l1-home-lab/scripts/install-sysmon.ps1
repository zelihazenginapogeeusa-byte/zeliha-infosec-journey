<#
.SYNOPSIS
    Sample script that automates installing Sysmon on the Windows 10 endpoint.

.DESCRIPTION
    Downloads Sysinternals Sysmon (or uses a local copy) and installs it using
    the configs/sysmonconfig-sample.xml file from this repo.
    Must be run in an elevated (Administrator) PowerShell session.

.NOTES
    Usage:
      .\install-sysmon.ps1 -ConfigPath "..\configs\sysmonconfig-sample.xml"
#>

param(
    [string]$ConfigPath = "..\configs\sysmonconfig-sample.xml",
    [string]$SysmonUrl  = "https://download.sysinternals.com/files/Sysmon.zip",
    [string]$WorkDir    = "$env:TEMP\sysmon-install"
)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as Administrator."
    exit 1
}

Write-Host "[1/4] Preparing working directory: $WorkDir"
New-Item -ItemType Directory -Force -Path $WorkDir | Out-Null

Write-Host "[2/4] Downloading Sysmon..."
$zipPath = Join-Path $WorkDir "Sysmon.zip"
Invoke-WebRequest -Uri $SysmonUrl -OutFile $zipPath
Expand-Archive -Path $zipPath -DestinationPath $WorkDir -Force

Write-Host "[3/4] Installing Sysmon (config: $ConfigPath)..."
$sysmonExe = Join-Path $WorkDir "Sysmon64.exe"
& $sysmonExe -accepteula -i $ConfigPath

Write-Host "[4/4] Checking Sysmon service status..."
Get-Service -Name "Sysmon64" -ErrorAction SilentlyContinue |
    Select-Object Name, Status, StartType | Format-Table -AutoSize

Write-Host "Install complete. Check logs under 'Event Viewer > Applications and Services Logs > Microsoft > Windows > Sysmon > Operational'."
