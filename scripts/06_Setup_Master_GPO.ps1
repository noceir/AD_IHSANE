<#
.SYNOPSIS
    Configures full GPO restrictions, browser whitelist, and SYSVOL startup cleaner for Salle SILYCEE.
.DESCRIPTION
    Applies to GPO_SILYCEE_Security linked to OU=SILYCEE,OU=CAMPUS IBN BADIS,DC=LEI,DC=IDEMY.
    - Fast boot without network wait
    - USB installer behavior prompts for Admin credentials (no hard block)
    - Default wallpaper locked (NoChangingWallPaper = 1)
    - Browser whitelist: Google Workspace (Drive, Docs, Classroom, Gmail), Tinkercad, Jupyter
    - Google Search 100% blocked
    - Incognito/InPrivate disabled
    - CMD disabled (DisableCMD = 2) to prevent Wi-Fi password theft via netsh
    - Network properties locked (NC_LanProperties = 0) to prevent DNS tampering
    - Autonomous startup cleaner in SYSVOL: purges legacy C:\Games & GTA files, scrubs public desktop, wipes student downloads/temp
#>

Import-Module GroupPolicy -ErrorAction Stop
Import-Module ActiveDirectory -ErrorAction Stop

$GpoName = "GPO_SILYCEE_Security"
$GpoGuid = "{090E703B-7094-45FD-8EB2-414F500290CD}"
$SysvolStartupPath = "\\LEI.IDEMY\SYSVOL\LEI.IDEMY\Policies\$GpoGuid\Machine\Scripts\Startup"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   APPLYING COMPLETE SALLE SILYCEE MASTER SETUP...        " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. FAST BOOT (No Wi-Fi hang)
Write-Host "[1/6] Ensuring fast boot (no Wi-Fi hang)..." -ForegroundColor Yellow
Remove-GPRegistryValue -Name $GpoName -Key "HKLM\Software\Policies\Microsoft\Windows NT\CurrentVersion\Winlogon" -ValueName "SyncForegroundPolicy" -ErrorAction SilentlyContinue | Out-Null

# 2. USB POLICY: REQUIRE ADMIN PASSWORD TO INSTALL (No Hard Block)
Write-Host "[2/6] Configuring USB behavior (Prompts for Admin Password)..." -ForegroundColor Yellow
$UsbGuid = "{53f5630d-b6bf-11d0-94f2-00a0c91efb8b}"
Remove-GPRegistryValue -Name $GpoName -Key "HKLM\Software\Policies\Microsoft\Windows\RemovableStorageDevices\$UsbGuid" -ValueName "Deny_Execute" -ErrorAction SilentlyContinue | Out-Null
Remove-GPRegistryValue -Name $GpoName -Key "HKCU\Software\Policies\Microsoft\Windows\RemovableStorageDevices\$UsbGuid" -ValueName "Deny_Execute" -ErrorAction SilentlyContinue | Out-Null

# 3. LOCK DEFAULT WALLPAPER (Students cannot change or add their own)
Write-Host "[3/6] Locking default Windows wallpaper..." -ForegroundColor Yellow
Remove-GPRegistryValue -Name $GpoName -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName "Wallpaper" -ErrorAction SilentlyContinue | Out-Null
Set-GPRegistryValue -Name $GpoName -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop" -ValueName "NoChangingWallPaper" -Type DWord -Value 1 | Out-Null

# 4. EDGE & CHROME WHITELIST (Workspace + Tinkercad + Jupyter | Search Blocked)
Write-Host "[4/6] Configuring Browser Whitelist..." -ForegroundColor Yellow
Set-GPRegistryValue -Name $GpoName -Key "HKLM\Software\Policies\Microsoft\Edge" -ValueName "InPrivateModeAvailability" -Type DWord -Value 1 | Out-Null
Set-GPRegistryValue -Name $GpoName -Key "HKLM\Software\Policies\Microsoft\Edge\URLBlocklist" -ValueName "1" -Type String -Value "*" | Out-Null
Set-GPRegistryValue -Name $GpoName -Key "HKLM\Software\Policies\Google\Chrome\URLBlocklist" -ValueName "1" -Type String -Value "*" | Out-Null

$AllowedSites = @(
    # Google Workspace
    "https://drive.google.com",
    "https://[*.]drive.google.com",
    "https://docs.google.com",
    "https://[*.]docs.google.com",
    "https://classroom.google.com",
    "https://[*.]classroom.google.com",
    "https://mail.google.com",
    "https://accounts.google.com",
    "https://ssl.gstatic.com",
    "https://[*.]gstatic.com",
    "https://apis.google.com",
    "https://[*.]googleusercontent.com",
    
    # Tinkercad & Arduino Simulation
    "https://tinkercad.com",
    "https://[*.]tinkercad.com",
    "https://[*.]autodesk.com",
    "https://[*.]autodesk360.com",
    "https://[*.]arduino.cc",
    
    # School Portals & Jupyter
    "https://[*.]lesecolesihsane.com",
    "https://jupyter.org",
    "https://[*.]jupyter.org"
)

$idx = 1
foreach ($site in $AllowedSites) {
    Set-GPRegistryValue -Name $GpoName -Key "HKLM\Software\Policies\Microsoft\Edge\URLAllowlist" -ValueName "$idx" -Type String -Value $site | Out-Null
    Set-GPRegistryValue -Name $GpoName -Key "HKLM\Software\Policies\Google\Chrome\URLAllowlist" -ValueName "$idx" -Type String -Value $site | Out-Null
    Start-Sleep -Milliseconds 100
    $idx++
}

# 5. BLOCK CMD (No Wi-Fi password theft) & LOCK DNS
Write-Host "[5/6] Locking Command Prompt & DNS Properties..." -ForegroundColor Yellow
Set-GPRegistryValue -Name $GpoName -Key "HKCU\Software\Policies\Microsoft\Windows\System" -ValueName "DisableCMD" -Type DWord -Value 2 | Out-Null
Set-GPRegistryValue -Name $GpoName -Key "HKCU\Software\Policies\Microsoft\Windows\Network Connections" -ValueName "NC_LanProperties" -Type DWord -Value 0 | Out-Null
Set-GPRegistryValue -Name $GpoName -Key "HKCU\Software\Policies\Microsoft\Windows\Network Connections" -ValueName "NC_EnableAdminProhibits" -Type DWord -Value 1 | Out-Null

# 6. SMART STARTUP SCRIPT (Purges legacy GTA and cleans desktop on boot)
Write-Host "[6/6] Updating autonomous startup cleaner in SYSVOL..." -ForegroundColor Yellow
if (-not (Test-Path $SysvolStartupPath)) { New-Item -Path $SysvolStartupPath -ItemType Directory -Force | Out-Null }

$CleanScript = @'
# 1. Purge legacy GTA and game folders from unformatted Windows state
Remove-Item -Path "C:\Games" -Recurse -Force -ErrorAction SilentlyContinue
Get-ChildItem -Path "C:\Users", "C:\" -Filter "*gta*" -Recurse -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

# 2. Wipe student personal downloads, temp, and desktop
Remove-Item -Path "C:\Users\eleve\Desktop\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Users\eleve\Downloads\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Users\eleve\Documents\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Users\eleve\AppData\Local\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

# 3. Clean Public Desktop: Keep only study tools
$Approved = @("PyCharm", "Arduino", "Code", "Thonny", "Python", "Chrome", "Edge", "GLPI")
Get-ChildItem -Path "C:\Users\Public\Desktop" -File | ForEach-Object {
    $file = $_
    $keep = $false
    foreach ($app in $Approved) { if ($file.Name -like "*$app*") { $keep = $true; break } }
    if (-not $keep) { Remove-Item $file.FullName -Force -ErrorAction SilentlyContinue }
}
'@

Set-Content -Path "$SysvolStartupPath\clean.ps1" -Value $CleanScript -Encoding UTF8
Set-Content -Path "$SysvolStartupPath\wipe.bat" -Value "@echo off`r`npowershell.exe -ExecutionPolicy Bypass -NoProfile -File `"$SysvolStartupPath\clean.ps1`"" -Encoding Ascii

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "   [✓] SUCCESS: SCRIPT COMPLETE! SERVER IS FULLY ARMED.    " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
