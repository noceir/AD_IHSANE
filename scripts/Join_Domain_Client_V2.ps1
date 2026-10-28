<#
================================================================================
  SALLE SILYCEE - MASTER CLIENT ONBOARDING SCRIPT (V2)
  Bulletproof Domain Join + Python/IDE Environment Fixer
================================================================================
#>

# 1. ELEVATION CHECK
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[!] ERROR: You must run this PowerShell script as Administrator!" -ForegroundColor Red
    Pause
    Exit
}

Clear-Host
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   SALLE SILYCEE - CLIENT ONBOARDING & SETUP (V2)          " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 2. WI-FI LOCK TO 'INF'
Write-Host "[1/6] Locking Wi-Fi to 'INF' only..." -ForegroundColor Yellow
netsh wlan add filter permission=allow ssid="INF" networktype=infrastructure 2>$null | Out-Null
netsh wlan add filter permission=denyall networktype=infrastructure 2>$null | Out-Null
netsh wlan set blockednetworks display=hide 2>$null | Out-Null
Write-Host "      [✓] Wi-Fi locked exclusively to 'INF'." -ForegroundColor Green

# 3. SET DNS & TEST CONNECTION TO DOMAIN CONTROLLER
Write-Host "[2/6] Configuring DNS to 10.12.43.253 and testing DC..." -ForegroundColor Yellow
Get-DnsClientServerAddress | Where-Object { $_.AddressFamily -eq 2 } | ForEach-Object {
    Set-DnsClientServerAddress -InterfaceIndex $_.InterfaceIndex -ServerAddresses "10.12.43.253" -ErrorAction SilentlyContinue
}
Clear-DnsClientCache

# Ping Domain Controller
if (-not (Test-Connection -ComputerName "10.12.43.253" -Count 2 -Quiet)) {
    Write-Host "[!] CRITICAL: Cannot reach Domain Controller at 10.12.43.253!" -ForegroundColor Red
    Write-Host "    Make sure you are connected to the 'INF' Wi-Fi." -ForegroundColor Yellow
    Pause
    Exit
}
Write-Host "      [✓] Domain Controller reached successfully!" -ForegroundColor Green

# 4. FIX PYTHON, VS CODE & IDE PERMISSIONS (PREVENT ACCESS DENIED)
Write-Host "[3/6] Fixing Python, VS Code & IDE permissions for all users..." -ForegroundColor Yellow

$PythonPaths = @()
if (Test-Path "C:\Python*") { $PythonPaths += (Get-Item "C:\Python*").FullName }
if (Test-Path "C:\Program Files\Python*") { $PythonPaths += (Get-Item "C:\Program Files\Python*").FullName }
$UserAppDatas = Get-ChildItem -Path "C:\Users\*\AppData\Local\Programs\Python\*" -ErrorAction SilentlyContinue
if ($UserAppDatas) { $PythonPaths += $UserAppDatas.FullName }

foreach ($p in $PythonPaths) {
    if (Test-Path $p) {
        Write-Host "      [+] Granting access to Python: $p" -ForegroundColor Cyan
        icacls "$p" /grant "Users:(OI)(CI)RX" /T /Q 2>$null | Out-Null
        icacls "$p" /grant "Domain Users:(OI)(CI)RX" /T /Q 2>$null | Out-Null
        
        $SysPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
        if ($SysPath -notlike "*$p*") {
            [Environment]::SetEnvironmentVariable("Path", "$SysPath;$p;$p\Scripts", [EnvironmentVariableTarget]::Machine)
            Write-Host "      [✓] Added $p to System PATH" -ForegroundColor Green
        }
    }
}

$OldPrograms = Get-ChildItem -Path "C:\Users\*\AppData\Local\Programs" -Directory -ErrorAction SilentlyContinue
foreach ($dir in $OldPrograms) {
    icacls "$($dir.FullName)" /grant "Users:(OI)(CI)RX" /T /Q 2>$null | Out-Null
    icacls "$($dir.FullName)" /grant "Domain Users:(OI)(CI)RX" /T /Q 2>$null | Out-Null
}

Copy-Item "$env:USERPROFILE\Desktop\*.lnk" "C:\Users\Public\Desktop\" -Force -ErrorAction SilentlyContinue
Write-Host "      [✓] IDE and Python access unlocked for all users!" -ForegroundColor Green

# 5. CONFIGURE AUTO-LOGIN FOR 'IDEMY\eleve'
Write-Host "[4/6] Configuring Windows AutoAdminLogon for IDEMY\eleve..." -ForegroundColor Yellow
$reg = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-ItemProperty -Path $reg -Name "AutoAdminLogon" -Value "1" -Type String
Set-ItemProperty -Path $reg -Name "DefaultDomainName" -Value "IDEMY" -Type String
Set-ItemProperty -Path $reg -Name "DefaultUserName" -Value "eleve" -Type String
Set-ItemProperty -Path $reg -Name "DefaultPassword" -Value "" -Type String
Write-Host "      [✓] Auto-login configured." -ForegroundColor Green

# 6. CHECK FOR OLD DOMAIN & PROCEED WITH DOMAIN JOIN
Write-Host "[5/6] Checking domain status..." -ForegroundColor Yellow
$sys = Get-WmiObject Win32_ComputerSystem
if ($sys.PartOfDomain -and ($sys.Domain -like "*LEI.ACADEMY*")) {
    Write-Host "[!] WARNING: This computer is trapped on the old domain ($($sys.Domain))!" -ForegroundColor Red
    Write-Host "    Switching to WORKGROUP first... The PC will reboot. Run this script again after reboot." -ForegroundColor Yellow
    Remove-Computer -WorkgroupName "WORKGROUP" -Force -Restart
    Exit
}

# 7. DOMAIN JOIN TO OU=SILYCEE
Write-Host "[6/6] Ready to join LEI.IDEMY..." -ForegroundColor Yellow
$n = Read-Host "Enter PC Number (e.g. 1 to 29)"
$ComputerName = "SILYCEE-PC$n"

Write-Host "Joining as $ComputerName into OU=SILYCEE..." -ForegroundColor Cyan

$cred = Get-Credential -UserName "IDEMY\Administrateur" -Message "Enter password for IDEMY\Administrateur"

Add-Computer -NewName $ComputerName `
             -DomainName "LEI.IDEMY" `
             -OUPath "OU=SILYCEE,OU=CAMPUS IBN BADIS,DC=LEI,DC=IDEMY" `
             -Credential $cred `
             -Restart -Force
