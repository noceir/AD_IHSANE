<#
.SYNOPSIS
    Master Client Provisioning Script for Salle SILYCEE (29 Laptops)
.DESCRIPTION
    1. Locks Wi-Fi exclusively to SSID 'INF' and hides all other networks.
    2. Copies all Desktop shortcuts (Python, Arduino, Java, VS Code, Thonny) to Public Desktop.
    3. Sets IPv4 DNS to Domain Controller IP (10.12.43.253).
    4. Sets Windows Registry to auto-logon as 'IDEMY\eleve' (blank password).
    5. Joins domain 'LEI.IDEMY' directly into 'OU=SILYCEE,OU=CAMPUS IBN BADIS,DC=LEI,DC=IDEMY'.
#>

netsh wlan add filter permission=allow ssid="INF" networktype=infrastructure
netsh wlan add filter permission=denyall networktype=infrastructure
netsh wlan set blockednetworks display=hide

Copy-Item "$env:USERPROFILE\Desktop\*" "C:\Users\Public\Desktop\" -Recurse -Force -ErrorAction SilentlyContinue

Get-DnsClientServerAddress | Where-Object {$_.AddressFamily -eq 2} | ForEach-Object {
    Set-DnsClientServerAddress -InterfaceIndex $_.InterfaceIndex -ServerAddresses "10.12.43.253" -ErrorAction SilentlyContinue
}

$reg = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-ItemProperty -Path $reg -Name "AutoAdminLogon" -Value "1" -Type String
Set-ItemProperty -Path $reg -Name "DefaultDomainName" -Value "IDEMY" -Type String
Set-ItemProperty -Path $reg -Name "DefaultUserName" -Value "eleve" -Type String
Set-ItemProperty -Path $reg -Name "DefaultPassword" -Value "" -Type String

$n = Read-Host "Enter PC Number (1 to 29)"
Add-Computer -NewName "SILYCEE-PC$n" `
             -DomainName "LEI.IDEMY" `
             -OUPath "OU=SILYCEE,OU=CAMPUS IBN BADIS,DC=LEI,DC=IDEMY" `
             -Credential (Get-Credential "IDEMY\Administrateur") `
             -Restart -Force
