<#
.SYNOPSIS
    Enables Unified Write Filter (UWF) on Windows 10/11 laptops for Session Wipe (Deep Freeze).
.DESCRIPTION
    Turns the C: volume into a read-only partition backed by a RAM overlay.
    All student downloads, temp files, and local profile modifications vanish upon reboot.
.NOTES
    Requires Windows 10/11 Enterprise or Education Edition.
#>

# Check Administrative Privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[!] Please run PowerShell as Administrator." -ForegroundColor Red
    exit
}

Write-Host "[+] Enabling DISM Feature Client-UnifiedWriteFilter..." -ForegroundColor Cyan
dism /online /enable-feature /featureName:Client-UnifiedWriteFilter /all /norestart

Write-Host "[+] Enabling UWF Filter Engine..." -ForegroundColor Cyan
uwfmgr filter enable

Write-Host "[+] Protecting Volume C: with UWF Overlay..." -ForegroundColor Cyan
uwfmgr volume protect C:

Write-Host "[✓] UWF (Deep Freeze) feature enabled! Please restart the computer to complete activation." -ForegroundColor Green
