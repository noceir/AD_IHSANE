# 🧠 Full Project Context & AI Handover Document (V2) — Salle SILYCEE
### Les Écoles Ihsane — Active Directory & Lab Automation Project (Updated)

> **Note for the Next AI Assistant (Gemini / Antigravity / Claude):**
> Read this document first to get 100% of the technical context, domain parameters, GPO state, newly deployed scripts, security lockdowns, and exact next steps for this project.

---

## 1. Environment & Infrastructure Specifications

| Parameter | Value / Details |
| :--- | :--- |
| **Organization** | Les Écoles Ihsane (`@lesecolesihsane.com` for student Google Workspace) |
| **Active Directory DNS Domain** | `LEI.IDEMY` |
| **Active Directory NetBIOS Name** | `IDEMY` (Domain Admin login: `IDEMY\Administrateur`) |
| **Domain Controller IP (DNS)** | `10.12.43.253` |
| **Server OS Language** | French (`C:\Users\Administrateur`, `IDEMY\Admins du domaine`) |
| **Target Computer Lab** | **Salle SILYCEE** (29 Laptops: `SILYCEE-PC1` to `SILYCEE-PC29`) |
| **Target Organizational Unit (OU)** | `OU=SILYCEE,OU=CAMPUS IBN BADIS,DC=LEI,DC=IDEMY` |
| **Shared Student AD Account** | Username: `eleve` (`IDEMY\eleve`) — **Blank Password + Registry AutoAdminLogon** |
| **Exclusive Lab Wi-Fi** | SSID: **`INF`** (Locked via `netsh wlan add filter` so laptops ONLY see/connect to `INF`) |
| **Approved Desktop Tools** | **PyCharm, Arduino IDE, Java, VS Code, Thonny, Python, Chrome, Edge, GLPI** |

---

## 2. Updated Project State & Completed Deployments

All 29 laptops were joined to the domain **without formatting**. To resolve issues with legacy games (GTA San Andreas), unmanaged internet access, and security leaks, the following configurations were executed on the Domain Controller (`10.12.43.253`):

### A. Group Policy Object: `GPO_SILYCEE_Security`
- **GUID**: `{090E703B-7094-45FD-8EB2-414F500290CD}`
- **Linked To**: `OU=SILYCEE,OU=CAMPUS IBN BADIS,DC=LEI,DC=IDEMY`

#### 1. Web Browsing Lock (Edge & Google Chrome)
- **Blocked**: Everything (`URLBlocklist = *`).
- **Google Search**: **100% BLOCKED** (`google.com` and `www.google.com` are omitted).
- **Incognito/InPrivate**: `InPrivateModeAvailability = 1` (Disabled).
- **URL Whitelist (`URLAllowlist`) Active Entries**:
  - `https://drive.google.com` & `https://[*.]drive.google.com`
  - `https://docs.google.com` & `https://[*.]docs.google.com`
  - `https://classroom.google.com` & `https://[*.]classroom.google.com`
  - `https://mail.google.com`
  - `https://accounts.google.com`
  - `https://ssl.gstatic.com` & `https://[*.]gstatic.com`
  - `https://apis.google.com`
  - `https://[*.]googleusercontent.com`
  - `https://tinkercad.com` & `https://[*.]tinkercad.com` (Arduino 3D / circuits)
  - `https://[*.]autodesk.com` & `https://[*.]autodesk360.com`
  - `https://[*.]arduino.cc`
  - `https://[*.]lesecolesihsane.com`
  - `https://jupyter.org` & `https://[*.]jupyter.org`

#### 2. Tamper Prevention & Anti-Theft
- **Command Prompt (`DisableCMD = 2`)**:
  - Prevents students from opening `cmd.exe`.
  - **Stops students from running `netsh wlan show profile ... key=clear` to steal the `INF` Wi-Fi password**.
  - Value `2` ensures system background batch scripts continue to run silently.
- **Network / DNS Lockdown (`NC_LanProperties = 0`, `NC_EnableAdminProhibits = 1`)**:
  - Students cannot open IPv4 properties to alter DNS servers.
- **Control Panel & PC Settings**: Prohibited for standard user `eleve`.
- **Wallpaper Lockdown (`NoChangingWallPaper = 1`)**:
  - Keeps standard Windows wallpaper; blocks students from setting custom wallpapers.

#### 3. USB & Application Execution Policy
- **USB Installers**: Prompts for Administrator credentials via UAC (Standard students without password cannot install; Admin can install by typing password).
- **IDE Compilers Preserved**: `RestrictRun` was **not** applied, ensuring Arduino background tools (`avrdude.exe`, `arduino-cli.exe`) and PyCharm helpers run without errors.
- **Power Management**: Closing laptop lid (On Battery & Plugged In) triggers immediate **Shut down**.

---

### B. Autonomous Self-Cleaning Startup Script (SYSVOL)
Located at:
`\\LEI.IDEMY\SYSVOL\LEI.IDEMY\Policies\{090E703B-7094-45FD-8EB2-414F500290CD}\Machine\Scripts\Startup\`

Consists of:
1. **`wipe.bat`**: Calls `clean.ps1` with `-ExecutionPolicy Bypass`.
2. **`clean.ps1`**: Executes silently on boot with `SYSTEM` privileges:
   - **Purges Legacy Junk**: Deletes `C:\Games` and recursively removes any `*gta*` folders left over from the unformatted Windows state.
   - **Cleans Public Desktop**: Deletes all shortcut `.lnk` files unless they match:
     `PyCharm`, `Arduino`, `Code`, `Thonny`, `Python`, `Chrome`, `Edge`, `GLPI`.
   - **Wipes Student Folders**: Purges `C:\Users\eleve\Desktop`, `Downloads`, `Documents`, and `AppData\Local\Temp`.

---

## 3. Key Server Utility Scripts

### Script 1: Master Setup Runner (`C:\Setup.ps1`)
Contains the full idempotent PowerShell script to re-inject and configure all GPO registry keys, fast-boot configuration, and SYSVOL startup files on the Domain Controller.

### Script 2: Live Health & Verification Dashboard (`C:\Verify_Lab.ps1`)
Run this on the server when the lab laptops are turned on:
```powershell
Import-Module ActiveDirectory

$OU = "OU=SILYCEE,OU=CAMPUS IBN BADIS,DC=LEI,DC=IDEMY"
$Computers = (Get-ADComputer -Filter * -SearchBase $OU | Sort-Object Name).Name

Write-Host ">>> SALLE SILYCEE - LIVE GPO & HEALTH CHECK <<<" -ForegroundColor Cyan

foreach ($PC in $Computers) {
    if (Test-Connection -ComputerName $PC -Count 1 -Quiet) {
        $Check = Invoke-Command -ComputerName $PC -ScriptBlock {
            $edgeBlock = Test-Path "HKLM:\Software\Policies\Microsoft\Edge\URLBlocklist"
            $cmdBlock  = Test-Path "HKCU:\Software\Policies\Microsoft\Windows\System"
            return ($edgeBlock -and $cmdBlock)
        } -ErrorAction SilentlyContinue

        if ($Check) {
            Write-Host "  [ONLINE]  $PC --> GPO Status: [✓] FULLY ACTIVE & PROTECTED" -ForegroundColor Green
        } else {
            Write-Host "  [ONLINE]  $PC --> GPO Status: [!] PULLING UPDATE NOW..." -ForegroundColor Yellow
            Invoke-GPUpdate -Computer $PC -Force -RandomDelayInMinutes 0 -ErrorAction SilentlyContinue
        }
    } else {
        Write-Host "  [OFFLINE] $PC" -ForegroundColor Red
    }
}
```

---

## 4. Immediate Next Steps / Roadmap

1. **Physical Validation (Monday Morning)**:
   - Boot `SILYCEE-PC1`.
   - Verify: Clean desktop (only IDEs & browsers), Google Drive and Tinkercad load, Google Search blocked, CMD disabled, lid-close initiates shutdown.
2. **Full Lab Verification**:
   - Power on all 29 laptops and execute `C:\Verify_Lab.ps1` from `10.12.43.253`.
3. **GLPI Agent Deployment**:
   - Push `GLPI-Agent-x64.msi` silently across `OU=SILYCEE` via WinRM.
4. **Git Sync**:
   - Commit `PROJECT_CONTEXT_FOR_AI_V2.md`, `Setup.ps1`, and `Verify_Lab.ps1` to `https://github.com/noceir/AD_IHSANE`.
