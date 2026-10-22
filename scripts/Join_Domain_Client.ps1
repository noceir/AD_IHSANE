<#
.SYNOPSIS
    Joins client laptop to domain LEI.IDEMY and places computer object directly into OU=SILYCEE.
.EXAMPLE
    .\Join_Domain_Client.ps1 -PCName "SILYCEE-PC01"
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$PCName,

    [string]$DomainName = "LEI.IDEMY",
    [string]$OUPath = "OU=SILYCEE,OU=CAMPUS IBN BADIS,DC=LEI,DC=IDEMY"
)

Write-Host "[+] Renaming computer to $PCName and joining domain $DomainName..." -ForegroundColor Cyan

Rename-Computer -NewName $PCName -Force
Add-Computer -DomainName $DomainName -OUPath $OUPath -Credential (Get-Credential) -Restart -Force
