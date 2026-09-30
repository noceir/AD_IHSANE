<#
.SYNOPSIS
    Joins client laptop to domain LEI.IDEMY and places computer object directly into OU=SI110.
.EXAMPLE
    .\Join_Domain_Client.ps1 -PCName "SI110-PC01"
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$PCName,

    [string]$DomainName = "LEI.IDEMY",
    [string]$OUPath = "OU=SI110,OU=CAMPUS IBN BADIS,DC=LEI,DC=IDEMY"
)

Write-Host "[+] Renaming computer to $PCName and joining domain $DomainName..." -ForegroundColor Cyan

Rename-Computer -NewName $PCName -Force
Add-Computer -DomainName $DomainName -OUPath $OUPath -Credential (Get-Credential) -Restart -Force
