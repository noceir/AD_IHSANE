# 🧠 Full Project Context & AI Handover Document — Salle SILYCEE
### Les Écoles Ihsane — Active Directory & Lab Automation Project

> **Note for the Next AI Assistant (Gemini / Antigravity):**
> Read this document first to get 100% of the technical context, domain parameters, GPO XML state, exact scripts used, troubleshooting history, and current deployment status for this project.

---

## 1. Environment & Infrastructure Specifications

| Parameter | Value / Details |
| :--- | :--- |
| **Organization** | Les Écoles Ihsane (`@lesecolesihsane.com` for student Google Workspace) |
| **Active Directory DNS Domain** | `LEI.IDEMY` |
| **Active Directory NetBIOS Name** | `IDEMY` (Important: Domain Admin login is `IDEMY\Administrateur`) |
| **Domain Controller IP (DNS)** | `10.12.43.253` |
| **Server OS Language** | French (`C:\Users\Administrateur`, `IDEMY\Admins du domaine`) |
| **Target Computer Lab** | **Salle SILYCEE** (29 Windows 10/11 Laptops: `SILYCEE-PC1` to `SILYCEE-PC29`) |
| **Target Organizational Unit (OU)** | `OU=SILYCEE,OU=CAMPUS IBN BADIS,DC=LEI,DC=IDEMY` |
| **Legacy Test OU** | `OU=SI110,OU=CAMPUS IBN BADIS,DC=LEI,DC=IDEMY` (Used during initial testing) |
| **Shared Student AD Account** | Username: `eleve` (`IDEMY\eleve` or `eleve@LEI.IDEMY`) — **Blank / Empty Password** |
| **Exclusive Lab Wi-Fi** | SSID: **`INF`** (Locked via `netsh wlan add filter` so laptops ONLY see/connect to `INF`) |
| **Permanent Lab Software** | **Python, Arduino IDE, Java, VS Code, Thonny** (Shortcuts copied to `C:\Users\Public\Desktop`) |

---

## 2. Core Project Requirements (From Management)

1. **Remote Software Installation**: Ability to push software from the Domain Controller to all 29 laptops remotely (via WinRM PowerShell Remoting or GPO) without touching each laptop.
2. **Strict Student Lockdowns**:
   - Students log in with a single shared account (`eleve` with no password) and save their personal schoolwork to Google Drive (`@lesecolesihsane.com`) in Chrome.
   - Standard user cannot install software (`Turn off Windows Installer` enabled for non-managed apps) or open Control Panel / PC Settings.
   - Laptops can ONLY connect to the **`INF`** Wi-Fi network; all other Wi-Fi networks (including student phone hotspots) are blocked and hidden.
3. **Ephemeral Sessions (Wipe on Lid Close / Reboot)**:
   - Closing the laptop lid (both **On Battery** and **Plugged In**) triggers an immediate **Shut down**.
   - On every startup, a GPO Startup Script (`wipe.bat`) wipes `C:\Users\eleve\Desktop`, `Downloads`, `Documents`, and `Temp`, while keeping the permanent programming tools (**Python, Arduino IDE, Java, VS Code, Thonny**) intact in `C:\Users\Public\Desktop` and `C:\Program Files`.

---

## 3. What Has Already Been Completed on the Server (`LEI.IDEMY`)

### A. Domain Password Policy & Shared User (`eleve`)
Executed on the Domain Controller:
```powershell
# 1. Disabled complexity and minimum password length to allow blank passwords
Set-ADDefaultDomainPasswordPolicy -Identity "LEI.IDEMY" -ComplexityEnabled $false -MinPasswordLength 0 -MinPasswordAge (New-TimeSpan -Days 0) -PasswordHistoryCount 0

# 2. Created OU=SILYCEE under OU=CAMPUS IBN BADIS
New-ADOrganizationalUnit -Name "SILYCEE" -Path "OU=CAMPUS IBN BADIS,DC=LEI,DC=IDEMY"

# 3. Created/Moved shared user 'eleve' with Blank Password into OU=SILYCEE
Set-ADUser -Identity "eleve" -PasswordNotRequired $true
Get-ADUser -Identity "eleve" | Move-ADObject -TargetPath "OU=SILYCEE,OU=CAMPUS IBN BADIS,DC=LEI,DC=IDEMY"
```

### B. Group Policy Object: `GPO_SILYCEE_Security`
- **GUID**: `{090E703B-7094-45FD-8EB2-414F500290CD}`
- **Linked To**: `OU=SILYCEE,OU=CAMPUS IBN BADIS,DC=LEI,DC=IDEMY`
- **Configured Policies**:
  1. **Computer > System Services > WinRM**: Startup Mode = `Automatic`
  2. **Computer > Admin Templates > WinRM Service > Allow remote server management through WinRM**: `Enabled` (IPv4 filter: `*`, IPv6 filter: `*`)
  3. **Computer > Registry Firewall Rule**: Inbound TCP Port `5985` allowed for WinRM
  4. **Computer > Admin Templates > Power Management > Button Settings**:
     - `Select the lid switch action (on battery)` = `Enabled` ➔ `Shut down`
     - `Select the lid switch action (plugged in)` = `Enabled` ➔ `Shut down`
  5. **Computer > Admin Templates > System > User Profiles**:
     - `Delete user profiles older than a specified number of days on system restart` = `Enabled` (`1` day)
  6. **Computer > Admin Templates > Windows Components > Windows Installer**:
     - `Turn off Windows Installer` = `Enabled` (`For non-managed applications only`)
  7. **Computer > Windows Settings > Scripts (Startup)**:
     - `wipe.bat` located in `\\LEI.IDEMY\SYSVOL\LEI.IDEMY\Policies\{090E703B-7094-45FD-8EB2-414F500290CD}\Machine\Scripts\Startup\wipe.bat`:
       ```cmd
       rd /s /q "C:\Users\eleve\Desktop" & mkdir "C:\Users\eleve\Desktop"
       rd /s /q "C:\Users\eleve\Downloads" & mkdir "C:\Users\eleve\Downloads"
       rd /s /q "C:\Users\eleve\Documents" & mkdir "C:\Users\eleve\Documents"
       del /f /s /q "C:\Users\eleve\AppData\Local\Temp\*"
       ```
  8. **User > Admin Templates > Control Panel**:
     - `Prohibit access to Control Panel and PC settings` = `Enabled`

---

## 4. What Has Been Executed on the Client Laptops (`SILYCEE-PC1` to `SILYCEE-PC29`)

### Master Client Provisioning Script (Run in Admin PowerShell on Each Laptop)
Once a laptop is connected to Wi-Fi **`INF`**, this script:
1. Locks Wi-Fi exclusively to `INF` and hides all other networks.
2. Copies all Desktop shortcuts (**Python, Arduino, Java, VS Code, Thonny**) from the local user to `C:\Users\Public\Desktop\`.
3. Sets IPv4 DNS to `10.12.43.253`.
4. Configures Windows Registry (`Winlogon`) to auto-login as `IDEMY\eleve` (blank password) on boot.
5. Joins the domain `LEI.IDEMY` directly into `OU=SILYCEE,OU=CAMPUS IBN BADIS,DC=LEI,DC=IDEMY` and reboots.

```powershell
netsh wlan add filter permission=allow ssid="INF" networktype=infrastructure
netsh wlan add filter permission=denyall networktype=infrastructure
netsh wlan set blockednetworks display=hide
Copy-Item "$env:USERPROFILE\Desktop\*" "C:\Users\Public\Desktop\" -Recurse -Force -ErrorAction SilentlyContinue
Get-DnsClientServerAddress | Where-Object {$_.AddressFamily -eq 2} | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex $_.InterfaceIndex -ServerAddresses "10.12.43.253" -ErrorAction SilentlyContinue }
$reg = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-ItemProperty -Path $reg -Name "AutoAdminLogon" -Value "1" -Type String
Set-ItemProperty -Path $reg -Name "DefaultDomainName" -Value "IDEMY" -Type String
Set-ItemProperty -Path $reg -Name "DefaultUserName" -Value "eleve" -Type String
Set-ItemProperty -Path $reg -Name "DefaultPassword" -Value "" -Type String
$pass = ConvertTo-SecureString "<SERVER_ADMIN_PASSWORD>" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential("IDEMY\Administrateur", $pass)
$n = Read-Host "Enter PC Number (01 to 29)"
Add-Computer -NewName "SILYCEE-PC$n" -DomainName "LEI.IDEMY" -OUPath "OU=SILYCEE,OU=CAMPUS IBN BADIS,DC=LEI,DC=IDEMY" -Credential $cred -Restart -Force
```

---

## 5. Known Issues Encountered & How We Solved Them

1. **Domain Admin Credential Format**:
   - Because the NetBIOS domain name is `IDEMY` while the DNS root is `LEI.IDEMY`, credentials must use **`IDEMY\Administrateur`** or **`Administrateur@LEI.IDEMY`**.
2. **Laptops Stuck on Old Deleted Domain (`LEI.ACADEMY`)**:
   - Some laptops (starting around PC #7) were previously joined to an old nonexistent domain called `LEI.ACADEMY`.
   - Running `Add-Computer` directly on those machines throws `FailToUnjoinDomain` because Windows tries to contact `LEI.ACADEMY` to unjoin first.
   - **Fix**: Switch the laptop to `WORKGROUP` first (`Remove-Computer -WorkgroupName "WORKGROUP" -Force -Restart` or via `sysdm.cpl` ➔ Workgroup `WORKGROUP`), reboot, and then run the join script.
3. **Per-User Installed Apps (VS Code / Thonny)**:
   - If VS Code or Thonny were installed in the local user's `C:\Users\pc\AppData\Local\Programs`, `eleve` cannot launch the shortcut unless the folder is copied to `C:\Program Files` or installed with `--scope machine`.

---

## 6. Useful Commands for Next Steps

### Check All Joined Laptops in `OU=SILYCEE` (Run on Server)
```powershell
Get-ADComputer -Filter * -SearchBase "OU=SILYCEE,OU=CAMPUS IBN BADIS,DC=LEI,DC=IDEMY" | Select-Object Name, DNSHostName
```

### Force Instant GPO Update on All Joined Laptops Remotely (Run on Server)
```powershell
Get-ADComputer -Filter * -SearchBase "OU=SILYCEE,OU=CAMPUS IBN BADIS,DC=LEI,DC=IDEMY" | ForEach-Object { Invoke-GPUpdate -Computer $_.Name -Force -RandomDelayInMinutes 0 }
```

### Push Software Remotely to All Laptops in `OU=SILYCEE` (Run on Server)
```powershell
$PCs = (Get-ADComputer -Filter * -SearchBase "OU=SILYCEE,OU=CAMPUS IBN BADIS,DC=LEI,DC=IDEMY").Name
Invoke-Command -ComputerName $PCs -ScriptBlock {
    Start-Process msiexec.exe -ArgumentList '/i "\\LEI-DC\SoftwareShare\app.msi" /qn /norestart' -Wait
}
```
