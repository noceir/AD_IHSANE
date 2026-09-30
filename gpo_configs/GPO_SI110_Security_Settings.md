# ⚙️ Group Policy Object Specification: GPO_SI110_Security

This document details all Group Policy settings configured for **`GPO_SI110_Security`** linked to `OU=SI110,OU=CAMPUS IBN BADIS,DC=LEI,DC=IDEMY`.

---

## 🔒 1. User Restrictions (Non-Admin Lockdown)

### Control Panel & PC Settings
- **Path**: `User Configuration` > `Policies` > `Administrative Templates` > `Control Panel`
- **Setting**: `Prohibit access to Control Panel and PC settings`
- **State**: `Enabled`
- **Effect**: Prevents student account `eleve` from opening Control Panel, modifying system settings, changing display resolutions, or altering network configs.

### System Tools & Registry
- **Path**: `User Configuration` > `Policies` > `Administrative Templates` > `System`
- **Setting**: `Prevent access to registry editing tools` -> `Enabled`
- **Setting**: `Prevent access to the command prompt` -> `Enabled (Disable script execution: No)`

---

## 🔋 2. Laptop Power Management (Lid-Close Session Wipe)

### Lid Close Shutdown Action
- **Path**: `Computer Configuration` > `Policies` > `Administrative Templates` > `System` > `Power Management` > `Button Settings`
- **Setting**: `Select the lid switch action (Plugged in)`
- **State**: `Enabled` -> Action: `Shut down`
- **Effect**: When a student finishes class and closes the laptop lid, the laptop automatically powers down. Combined with Unified Write Filter (UWF), this completely purges session files.

---

## 📶 3. Wireless Network Policy (Wi-Fi Auto-Connect)

### Automatic Wi-Fi Deployment
- **Path**: `Computer Configuration` > `Policies` > `Windows Settings` > `Security Settings` > `Wireless Network (IEEE 802.11) Policies`
- **Setting**: `Create New Wireless Network Policy (Windows Vista and Later)`
- **Network Name (SSID)**: `IHSANE_SCHOOL_WIFI`
- **Authentication**: `WPA2-Personal` / `AES`
- **Connection**: `Connect automatically when this network is in range`
- **Effect**: Laptops connect to school Wi-Fi at boot time before user login. Password is encrypted and hidden from students.

---

## 🧹 4. User Profile Eviction (Fallback Cleanup)

### Profile Cleanup on Reboot
- **Path**: `Computer Configuration` > `Policies` > `Administrative Templates` > `System` > `User Profiles`
- **Setting**: `Delete cached copies of roaming profiles` -> `Enabled`
- **Setting**: `Delete user profiles older than specified number of days on system restart` -> `Enabled` (Value: `1` day)
