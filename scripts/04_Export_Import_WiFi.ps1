<#
.SYNOPSIS
    Exports or Imports Wi-Fi network profile XML files via netsh.
.DESCRIPTION
    Allows exporting connected Wi-Fi profile from master laptop and deploying it to shared network path for GPO deployment.
#>

param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("Export", "Import")]
    [string]$Action,

    [string]$WiFiSSID = "IHSANE_SCHOOL_WIFI",
    [string]$ProfilePath = "\\LEI-DC\SoftwareShare\WiFi-Profile.xml"
)

if ($Action -eq "Export") {
    Write-Host "[+] Exporting Wi-Fi profile '$WiFiSSID' to C:\..." -ForegroundColor Cyan
    netsh wlan export profile name="$WiFiSSID" folder="C:\" key=clear
    Write-Host "[✓] Wi-Fi profile exported. Please copy file to $ProfilePath" -ForegroundColor Green
}
elseif ($Action -eq "Import") {
    Write-Host "[+] Importing Wi-Fi profile from $ProfilePath..." -ForegroundColor Cyan
    if (Test-Path $ProfilePath) {
        netsh wlan add profile filename="$ProfilePath" user=all
        Write-Host "[✓] Wi-Fi profile successfully added!" -ForegroundColor Green
    } else {
        Write-Host "[!] Error: Profile XML not found at $ProfilePath" -ForegroundColor Red
    }
}
