# 🧠 Full Project Context & AI Handover Document (V2) — Salle SILYCEE
### Les Écoles Ihsane — Active Directory & Lab Automation Project (Updated)

> **Note for the Next AI Assistant (Gemini / Antigravity / Claude):**
> Read this document first to get 100% of the technical context, domain parameters, GPO state, newly deployed scripts, security lockdowns, troubleshooting solutions, and exact next steps for this project.

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

## 3. Solved Traps & Troubleshooting Guide

### 1. Python Blocked Even With Administrator Password
- **Cause**: The GPO had `Turn off Windows Installer` (`DisableMSI = 1` or `2`) enabled. Python's executable unpacks embedded `.msi` files, which Windows Installer blocked with *"The system administrator has set policies to prevent this installation"*.
- **Fix**: Executed `10_Unlock_Windows_Installer.ps1` (`DisableMSI = 0`) so administrators can install software.

### 2. Python / VS Code Broken for `IDEMY\eleve` (Access Denied)
- **Cause**: Apps were installed in the old local user's `C:\Users\<old>\AppData\Local\Programs\`. When domain user `eleve` logs in, Windows restricts cross-user AppData access.
- **Fix**: 
  1. `Join_Domain_Client_V2.ps1` automatically grants read/execute permissions to `Domain Users` via `icacls` and registers Python in the System `PATH`.
  2. For new Python installs, always use `InstallAllUsers=1 PrependPath=1` (script `09_Deploy_Python_AllUsers.ps1`), which installs to `C:\Program Files\Python`.

---

## 4. Complete Script Inventory (`scripts/`)

| Script | Purpose | Where to Run |
| :--- | :--- | :--- |
| `01_Create_OU_and_SharedUser.ps1` | Creates `OU=SILYCEE` and student user `eleve` | Domain Controller |
| `02_Set_DomainPasswordPolicy.ps1` | Allows blank passwords in domain | Domain Controller |
| `03_Deploy_RemoteSoftware.ps1` | General silent MSI/EXE push via WinRM | Domain Controller |
| `04_Export_Import_WiFi.ps1` | Netsh Wi-Fi profile exporter/importer | Client / DC |
| `05_Enable_UWF_DeepFreeze.ps1` | Enables Unified Write Filter on C: | Client Laptop |
| `06_Setup_Master_GPO.ps1` | **Full GPO master setup** (fast boot, whitelist, CMD block, SYSVOL cleaner) | Domain Controller |
| `07_Verify_Lab_Health.ps1` | **Live health check & GPO sync dashboard** | Domain Controller |
| `08_Deploy_GLPI_Agent.ps1` | Silent GLPI Agent installation push | Domain Controller |
| `09_Deploy_Python_AllUsers.ps1` | Silent Python push with `InstallAllUsers=1` | Domain Controller |
| `10_Unlock_Windows_Installer.ps1` | Unlocks `DisableMSI` so admins can install apps | Domain Controller |
| `Join_Domain_Client.ps1` | Original client domain join script | Client Laptop |
| `Join_Domain_Client_V2.ps1` | **Bulletproof client join** (fixes Python/IDE permissions, System PATH, Wi-Fi `INF`) | Client Laptop |

---

## 5. Next Steps for Any AI Harness Working on This Project

1. **Verify Status on Monday Morning**:
   Run `scripts/07_Verify_Lab_Health.ps1` from the DC to see which laptops are online and confirmed protected.
2. **Deploy Python or GLPI**:
   Use `scripts/09_Deploy_Python_AllUsers.ps1` and `scripts/08_Deploy_GLPI_Agent.ps1`.
3. **If Provisioning a New Laptop**:
   Use `scripts/Join_Domain_Client_V2.ps1` directly on the laptop.
