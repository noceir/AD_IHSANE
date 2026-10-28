<#
.SYNOPSIS
    Pushes silent Python installation for all users across all 29 laptops in Salle SILYCEE.
.DESCRIPTION
    Installs Python into C:\Program Files\Python, adds it to the System PATH, and makes it
    available to all users (including IDEMY\eleve) without per-user AppData permission issues.
#>

param (
    [string]$InstallerPath = "\\10.12.43.253\LabApps$\python-installer.exe",
    [string]$SearchBaseOU  = "OU=SILYCEE,OU=CAMPUS IBN BADIS,DC=LEI,DC=IDEMY"
)

Import-Module ActiveDirectory

$Computers = (Get-ADComputer -Filter * -SearchBase $SearchBaseOU).Name

if (-not $Computers) {
    Write-Host "[!] No computer objects found in $SearchBaseOU." -ForegroundColor Red
    exit
}

Write-Host "[+] Deploying Python (AllUsers) to $($Computers.Count) laptops in SILYCEE..." -ForegroundColor Cyan

Invoke-Command -ComputerName $Computers -ScriptBlock {
    param($Path)
    Write-Host "Installing Python silently on $env:COMPUTERNAME..."
    
    # InstallAllUsers=1 installs to Program Files, PrependPath=1 sets system PATH
    Start-Process -FilePath $Path -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1 Include_test=0" -Wait
    
    Write-Host "[✓] Python successfully installed for all users on $env:COMPUTERNAME!" -ForegroundColor Green
} -ArgumentList $InstallerPath

Write-Host "`n[✓] Python deployment completed across all available laptops!" -ForegroundColor Green
