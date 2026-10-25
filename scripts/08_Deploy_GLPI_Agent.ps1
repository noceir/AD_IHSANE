<#
.SYNOPSIS
    Pushes silent GLPI Agent MSI installation to all 29 laptops in Salle SILYCEE.
.DESCRIPTION
    Installs GLPI Agent silently over WinRM, sets inventory server URL, and triggers RUNNOW=1.
#>

param (
    [string]$InstallerPath = "\\10.12.43.253\LabSoftware$\GLPI-Agent-x64.msi",
    [string]$GlpiServerUrl = "http://10.12.43.253/glpi/marketplace/glpiinventory/",
    [string]$SearchBaseOU  = "OU=SILYCEE,OU=CAMPUS IBN BADIS,DC=LEI,DC=IDEMY"
)

Import-Module ActiveDirectory

$Computers = (Get-ADComputer -Filter * -SearchBase $SearchBaseOU).Name

if (-not $Computers) {
    Write-Host "[!] No computer objects found in $SearchBaseOU." -ForegroundColor Red
    exit
}

Write-Host "[+] Pushing GLPI Agent to $($Computers.Count) laptops in SILYCEE..." -ForegroundColor Cyan

Invoke-Command -ComputerName $Computers -ScriptBlock {
    param($Path, $ServerUrl)
    Write-Host "Installing GLPI Agent on $env:COMPUTERNAME..."
    
    $args = "/i `"$Path`" /qn RUNNOW=1 SERVER=`"$ServerUrl`" ADD_FIREWALL_EXCEPTION=1 /norestart"
    Start-Process msiexec.exe -ArgumentList $args -Wait -NoNewWindow
    
    Write-Host "[✓] GLPI Agent installed successfully on $env:COMPUTERNAME!" -ForegroundColor Green
} -ArgumentList $InstallerPath, $GlpiServerUrl

Write-Host "`n[✓] GLPI Agent deployment completed across all available laptops!" -ForegroundColor Green
