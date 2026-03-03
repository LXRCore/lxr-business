# 🐺 LXR-Management

> **wolves.land — The Land of Wolves** | Developed by [iBoss21](https://github.com/iboss21) / The Lux Empire

**LXR-Management** combines both **lxr-bossmenu** and **lxr-gangmenu** into one powerful management resource using **lxr-menu** and **lxr-input**, with full SQL support for managing society and gang funds.

---

```
██╗     ██╗  ██╗██████╗       ███╗   ███╗ █████╗ ███╗   ██╗ █████╗  ██████╗ ███████╗███╗   ███╗███████╗███╗   ██╗████████╗
██║     ╚██╗██╔╝██╔══██╗      ████╗ ████║██╔══██╗████╗  ██║██╔══██╗██╔════╝ ██╔════╝████╗ ████║██╔════╝████╗  ██║╚══██╔══╝
██║      ╚███╔╝ ██████╔╝█████╗██╔████╔██║███████║██╔██╗ ██║███████║██║  ███╗█████╗  ██╔████╔██║█████╗  ██╔██╗ ██║   ██║   
██║      ██╔██╗ ██╔══██╗╚════╝██║╚██╔╝██║██╔══██║██║╚██╗██║██╔══██║██║   ██║██╔══╝  ██║╚██╔╝██║██╔══╝  ██║╚██╗██║   ██║   
███████╗██╔╝ ██╗██║  ██║      ██║ ╚═╝ ██║██║  ██║██║ ╚████║██║  ██║╚██████╔╝███████╗██║ ╚═╝ ██║███████╗██║ ╚████║   ██║   
╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝      ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═══╝   ╚═╝   
```

---

## ═══════════════════════════════════════════════════════
## 🌐 Server Information
## ═══════════════════════════════════════════════════════

| Field       | Value                                             |
|-------------|---------------------------------------------------|
| **Server**  | The Land of Wolves 🐺                             |
| **Type**    | Serious Hardcore Roleplay — Georgian RP 🇬🇪        |
| **Website** | https://www.wolves.land                           |
| **Discord** | https://discord.gg/CrKcWdfd3A                    |
| **Store**   | https://theluxempire.tebex.io                    |
| **Author**  | iBoss21 / The Lux Empire                         |

---

## ═══════════════════════════════════════════════════════
## 📦 Framework Support
## ═══════════════════════════════════════════════════════

| Framework       | Status       |
|-----------------|--------------|
| LXR-Core        | ✅ Primary   |
| RSG-Core        | ✅ Primary   |
| VORP Core       | ✅ Supported |
| RedEM:RP        | 🔄 Optional  |
| QBR-Core        | 🔄 Optional  |
| QR-Core         | 🔄 Optional  |
| Standalone      | 🔄 Fallback  |

---

## ═══════════════════════════════════════════════════════
## 🔧 Dependencies
## ═══════════════════════════════════════════════════════

- [lxr-core](https://github.com/LXRCore/lxr-core)
- [lxr-smallresources](https://github.com/LXRCore/lxr-smallresources) (For the logs)
- [lxr-input](https://github.com/LXRCore/lxr-input)
- [lxr-menu](https://github.com/LXRCore/lxr-menu)
- [lxr-inventory](https://github.com/LXRCore/lxr-inventory)
- [lxr-clothing](https://github.com/LXRCore/lxr-clothing)
- [oxmysql](https://github.com/overextended/oxmysql)

---

## ═══════════════════════════════════════════════════════
## 📸 Screenshots
## ═══════════════════════════════════════════════════════

![Boss Menu](https://i.imgur.com/9yiQZDX.png)
![Gang Menu](https://i.imgur.com/MRMWeqX.png)

---

## ═══════════════════════════════════════════════════════
## 🛠️ Installation
## ═══════════════════════════════════════════════════════

### Manual Installation

1. **Download** the resource and place the `lxr-management` folder into your `[lxr]` directory.
2. **Import** `lxr-management.sql` into your database.
3. **Configure** `config.lua` — set the coordinates for boss/gang menu locations.
4. **Ensure** the resource is named exactly `lxr-management` (resource name protection is active).
5. **Restart** the script or your server to apply changes.

---

## ═══════════════════════════════════════════════════════
## ⚙️ Database Setup
## ═══════════════════════════════════════════════════════

> **IMPORTANT**:
> You must manually add a row in the `management_menu` table for any custom jobs or gangs.
> Boss and gang accounts share the same table — differentiated by the `menu_type` column.

![Database](https://i.imgur.com/JZnEK4M.png)

---

## ═══════════════════════════════════════════════════════
## 📄 License
## ═══════════════════════════════════════════════════════

```
© 2026 iBoss21 / The Lux Empire | wolves.land | All Rights Reserved

LXRCore Framework — lxr-management
This program is free software: you can redistribute it and/or modify
it under the terms of the MIT License.
```

---

*With **LXR-Management**, you can seamlessly manage both society and gang funds, simplify menu operations, and enjoy full SQL integration. Get ready to lead like never before! 🐺*
