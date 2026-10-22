# 🔧 System Administrator Operations & Maintenance Guide — Salle SILYCEE

## Daily & Weekly Maintenance Checklist

### 1. Pushing New Software to the 29 Lab Laptops
When a teacher requests new software (e.g. Python, VS Code, GeoGebra, Office):
1. Download the `.msi` or `.exe` installer.
2. Save it to `\\LEI-DC\SoftwareShare\`.
3. Open PowerShell as Admin on Domain Controller and run:
   ```powershell
   .\scripts\03_Deploy_RemoteSoftware.ps1 -InstallerPath "\\LEI-DC\SoftwareShare\Installer.msi"
   ```

### 2. Updating Windows / Software (Servicing Mode for UWF)
Because UWF protects drive C:, updates must be committed using UWF servicing mode:
```cmd
uwfmgr servicing enable
```
Or temporarily disable UWF, reboot, install updates, re-enable UWF:
```cmd
uwfmgr filter disable
:: Reboot PC -> Install Updates -> Re-enable
uwfmgr filter enable
uwfmgr volume protect C:
```

### 3. Adding New Laptops to Room SILYCEE
To join laptops `SILYCEE-PC01` through `SILYCEE-PC29`:
1. Run `.\scripts\Join_Domain_Client.ps1 -PCName "SILYCEE-PC01"`.
2. Move computer object into `OU=SILYCEE` in `dsa.msc` if joined manually.
3. Run `.\scripts\05_Enable_UWF_DeepFreeze.ps1` as Admin on the laptop.
