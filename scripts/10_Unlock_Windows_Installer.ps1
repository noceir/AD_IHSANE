<#
.SYNOPSIS
    Unlocks Windows Installer (DisableMSI) in GPO_SILYCEE_Security.
.DESCRIPTION
    Resolves the "The system administrator has set policies to prevent this installation" error
    when installing Python or MSI software with an Admin password.
#>

Import-Module GroupPolicy

$GpoName = "GPO_SILYCEE_Security"

Write-Host "[+] Unlocking Windows Installer in $GpoName..." -ForegroundColor Cyan

Remove-GPRegistryValue -Name $GpoName -Key "HKLM\Software\Policies\Microsoft\Windows\Installer" -ValueName "DisableMSI" -ErrorAction SilentlyContinue | Out-Null
Set-GPRegistryValue -Name $GpoName -Key "HKLM\Software\Policies\Microsoft\Windows\Installer" -ValueName "DisableMSI" -Type DWord -Value 0 | Out-Null

Write-Host "[✓] Windows Installer unlocked! Administrators can now install software without policy blocks." -ForegroundColor Green
