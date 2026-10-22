# 🗺️ Technical Architecture Diagram & Flow Guide — Salle SILYCEE

## Multi-Class High-Volume Design (29 Laptops / Wi-Fi: `inf lycee`)

```
+-----------------------------------------------------------------------+
|                         ACTIVE DIRECTORY DOMAIN                        |
|                               (LEI.IDEMY)                             |
|                                                                       |
|  OU: CAMPUS IBN BADIS                                                 |
|    └── OU: SILYCEE                                                    |
|         ├── GPO: GPO_SILYCEE_Security                                 |
|         ├── Shared User: eleve (No Password)                          |
|         └── Computers: SILYCEE-PC01 ... SILYCEE-PC29                  |
+-----------------------------------------------------------------------+
                                   |
                                   v
+-----------------------------------------------------------------------+
|                      LAPTOP CLIENT INSTANTIATION                       |
|                                                                       |
|  1. Laptop powers on -> Auto-connects ONLY to Wi-Fi 'inf lycee'       |
|  2. Windows logon -> Auto-logon as 'eleve' in 5 seconds               |
|  3. Student opens Chrome -> Signs into @lesecolesihsane.com           |
|  4. All assignments/code saved in personal Google Drive               |
+-----------------------------------------------------------------------+
                                   |
                                   v
+-----------------------------------------------------------------------+
|                     SESSION CLEANUP & DEEP FREEZE                     |
|                                                                       |
|  1. Student closes laptop lid at end of period                        |
|  2. GPO triggers immediate Shutdown                                   |
|  3. Unified Write Filter (UWF) discards RAM overlay                   |
|  4. Next class opens lid -> 100% Factory-Pristine Workstation         |
+-----------------------------------------------------------------------+
```
