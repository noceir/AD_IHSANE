# 🗺️ Technical Architecture Diagram & Flow Guide

## Multi-Class High-Volume Design (300+ Students / 11 Classes)

```
+-----------------------------------------------------------------------+
|                         ACTIVE DIRECTORY DOMAIN                        |
|                               (LEI.IDEMY)                             |
|                                                                       |
|  OU: CAMPUS IBN BADIS                                                 |
|    └── OU: SI110                                                      |
|         ├── GPO: GPO_SI110_Security                                   |
|         ├── Shared User: eleve (No Password)                          |
|         └── Computers: SI110-PC01 ... SI110-PC27                      |
+-----------------------------------------------------------------------+
                                   |
                                   v
+-----------------------------------------------------------------------+
|                      LAPTOP CLIENT INSTANTIATION                       |
|                                                                       |
|  1. Laptop powers on -> Auto-connects to IHSANE_SCHOOL_WIFI           |
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
