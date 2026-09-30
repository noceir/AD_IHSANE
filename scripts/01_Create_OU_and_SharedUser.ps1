<#
.SYNOPSIS
    Creates Organizational Unit SI110 and the shared student account 'eleve'.
.DESCRIPTION
    Script for Active Directory Domain Controller (LEI.IDEMY).
    Creates OU=SI110 and a shared user account 'eleve' configured with no password,
    password never expires, and user cannot change password.
.NOTES
    Domain: LEI.IDEMY
    Target OU: OU=SI110,OU=CAMPUS IBN BADIS,DC=LEI,DC=IDEMY
#>

param (
    [string]$DomainName = "LEI.IDEMY",
    [string]$OUName = "SI110",
    [string]$ParentOU = "OU=CAMPUS IBN BADIS,DC=LEI,DC=IDEMY",
    [string]$UserName = "eleve"
)

Import-Module ActiveDirectory

$OUPath = "OU=$OUName,$ParentOU"

# 1. Create OU if it does not exist
if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$OUName'" -ErrorAction SilentlyContinue)) {
    Write-Host "[+] Creating Organizational Unit: $OUPath..." -ForegroundColor Green
    New-ADOrganizationalUnit -Name $OUName -Path $ParentOU -ProtectedFromAccidentalDeletion $true
} else {
    Write-Host "[!] OU '$OUName' already exists at $OUPath." -ForegroundColor Yellow
}

# 2. Create Shared User 'eleve' without password
if (-not (Get-ADUser -Filter "SamAccountName -eq '$UserName'" -ErrorAction SilentlyContinue)) {
    Write-Host "[+] Creating Shared Account '$UserName'..." -ForegroundColor Green
    
    # Create user with blank password
    New-ADUser -Name $UserName `
               -SamAccountName $UserName `
               -UserPrincipalName "$UserName@$DomainName" `
               -Enabled $true `
               -CannotChangePassword $true `
               -PasswordNeverExpires $true `
               -Path $OUPath
               
    # Set PasswordNotRequired attribute for blank password support
    Set-ADUser -Identity $UserName -PasswordNotRequired $true
    
    Write-Host "[✓] Account '$UserName' created successfully in $OUPath without password!" -ForegroundColor Green
} else {
    Write-Host "[!] Account '$UserName' already exists." -ForegroundColor Yellow
}
