<#
.SYNOPSIS
    Exports or Imports 'inf lycee' Wi-Fi network profile XML and locks down other Wi-Fi networks.
.DESCRIPTION
    Allows exporting connected 'inf lycee' Wi-Fi profile from master laptop, importing it to all 29 laptops,
    and adding a netsh filter so laptops can ONLY see and connect to 'inf lycee'.
#>

param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("Export", "Import")]
    [string]$Action,

    [string]$WiFiSSID = "inf lycee",
    [string]$ProfilePath = "\\LEI-DC\SoftwareShare\WiFi-inf-lycee.xml"
)

if ($Action -eq "Export") {
    Write-Host "[+] Exporting Wi-Fi profile '$WiFiSSID' to C:\..." -ForegroundColor Cyan
    netsh wlan export profile name="$WiFiSSID" folder="C:\" key=clear
    Write-Host "[✓] Wi-Fi profile exported. Please copy the XML file to $ProfilePath" -ForegroundColor Green
}
elseif ($Action -eq "Import") {
    Write-Host "[+] Importing Wi-Fi profile from $ProfilePath..." -ForegroundColor Cyan
    if (Test-Path $ProfilePath) {
        # 1. Add the Wi-Fi Profile for all users
        netsh wlan add profile filename="$ProfilePath" user=all

        # 2. Restrict Laptop to ONLY connect to 'inf lycee' (Block student mobile hotspots & other Wi-Fis)
        netsh wlan add filter permission=allow ssid="$WiFiSSID" networktype=infrastructure
        netsh wlan add filter permission=denyall networktype=infrastructure
        netsh wlan set blockednetworks display=hide

        Write-Host "[✓] Wi-Fi profile '$WiFiSSID' added and locked exclusively!" -ForegroundColor Green
    } else {
        Write-Host "[!] Error: Profile XML not found at $ProfilePath" -ForegroundColor Red
    }
}
