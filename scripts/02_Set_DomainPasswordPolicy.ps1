<#
.SYNOPSIS
    Disables Password Complexity and Minimum Password Length on Active Directory.
.DESCRIPTION
    Updates Default Domain Password Policy on LEI.IDEMY to allow simple or blank passwords
    for shared computer lab accounts.
#>

param (
    [string]$DomainIdentity = "LEI.IDEMY"
)

Import-Module ActiveDirectory

Write-Host "[+] Updating Active Directory Default Domain Password Policy..." -ForegroundColor Cyan

Set-ADDefaultDomainPasswordPolicy -Identity $DomainIdentity `
                                  -ComplexityEnabled $false `
                                  -MinPasswordLength 0 `
                                  -MinPasswordAge (New-TimeSpan -Days 0) `
                                  -PasswordHistoryCount 0

Write-Host "[+] Refreshing Group Policy..." -ForegroundColor Cyan
gpupdate /force

Write-Host "[✓] Password Policy updated! Complexity disabled and Minimum Length set to 0." -ForegroundColor Green
