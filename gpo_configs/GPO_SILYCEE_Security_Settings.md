# ⚙️ Group Policy Object Specification: GPO_SILYCEE_Security

This document details all Group Policy settings configured for **`GPO_SILYCEE_Security`** linked to `OU=SILYCEE,OU=CAMPUS IBN BADIS,DC=LEI,DC=IDEMY` (29 Laptops).

---

## 🔒 1. User Restrictions & Blocking Specific Programs

### Control Panel & PC Settings
- **Path**: `User Configuration` > `Policies` > `Administrative Templates` > `Control Panel`
- **Setting**: `Prohibit access to Control Panel and PC settings`
- **State**: `Enabled`
- **Effect**: Prevents student account `eleve` from opening Control Panel, modifying system settings, or altering network configs.

### Block Specific Programs from Running or Installing
- **Path**: `User Configuration` > `Policies` > `Administrative Templates` > `System`
- **Setting**: `Don't run specified Windows applications` -> `Enabled`
  - Click **Show...** and add any blocked `.exe` names (e.g., `Steam.exe`, `Discord.exe`, `cmd.exe`, `powershell.exe`, `regedit.exe`, `uTorrent.exe`, `setup.exe`, `install.exe`).
- **Path (Windows Installer Block)**: `Computer Configuration` > `Policies` > `Administrative Templates` > `Windows Components` > `Windows Installer`
- **Setting**: `Turn off Windows Installer` -> `Enabled` (Disable for non-managed apps).

---

## 📶 2. Exclusive Wi-Fi Policy (`inf lycee` ONLY)

To ensure the 29 laptops **ONLY connect to `inf lycee`** and cannot connect to student phone hotspots or other Wi-Fi networks:

### Method A: Wireless Network (IEEE 802.11) GPO
- **Path**: `Computer Configuration` > `Policies` > `Windows Settings` > `Security Settings` > `Wireless Network (IEEE 802.11) Policies`
- **General Tab**: Add Infrastructure network **`inf lycee`**.
- **Network Permissions Tab**:
  1. Click **Add...** -> Permission: **Allow** -> SSID: **`inf lycee`** -> Network Type: `Infrastructure`.
  2. Check ✅ **Prevent connections to ad-hoc networks**.
  3. Check ✅ **Prevent connections to infrastructure networks** (this blocks all other Wi-Fi networks except `inf lycee`).
  4. Check ✅ **Don't display denied networks in Check for Available Networks** (hides all other Wi-Fis from the tray).

### Method B: Netsh Startup Script
Runs `04_Export_Import_WiFi.ps1 -Action Import` at boot, which imports the `inf lycee` XML profile and runs:
```cmd
netsh wlan add filter permission=allow ssid="inf lycee" networktype=infrastructure
netsh wlan add filter permission=denyall networktype=infrastructure
netsh wlan set blockednetworks display=hide
```

---

## 🔋 3. Laptop Power Management (Lid-Close Session Wipe)

### Lid Close Shutdown Action
- **Path**: `Computer Configuration` > `Policies` > `Administrative Templates` > `System` > `Power Management` > `Button Settings`
- **Setting**: `Select the lid switch action (Plugged in)` & `(On battery)`
- **State**: `Enabled` -> Action: `Shut down`
- **Effect**: When a student finishes class and closes the laptop lid, the laptop automatically powers down. Combined with Unified Write Filter (UWF), this completely purges session files.

---

## 🧹 4. User Profile Eviction (Fallback Cleanup)

### Profile Cleanup on Reboot
- **Path**: `Computer Configuration` > `Policies` > `Administrative Templates` > `System` > `User Profiles`
- **Setting**: `Delete cached copies of roaming profiles` -> `Enabled`
- **Setting**: `Delete user profiles older than specified number of days on system restart` -> `Enabled` (Value: `1` day)
