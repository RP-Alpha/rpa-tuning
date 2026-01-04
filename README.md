# rpa-tuning

<div align="center">

![GitHub Release](https://img.shields.io/github/v/release/RP-Alpha/rpa-tuning?style=for-the-badge&logo=github&color=blue)
![GitHub commits](https://img.shields.io/github/commits-since/RP-Alpha/rpa-tuning/latest?style=for-the-badge&logo=git&color=green)
![License](https://img.shields.io/github/license/RP-Alpha/rpa-tuning?style=for-the-badge&color=orange)
![Downloads](https://img.shields.io/github/downloads/RP-Alpha/rpa-tuning/total?style=for-the-badge&logo=github&color=purple)

**Mechanic Shops + Performance Handling Tuning**

*Similar to jg-tuning*

</div>

---

## ✨ Features

- 🔧 **Cosmetic Mods** - Engine, brakes, suspension, armor, turbo, etc.
- 🏎️ **Performance Tuning** - Adjust vehicle handling properties (drive force, brakes, traction)
- 🌈 **RGB Neons** - Full color customization with live preview
- 💡 **Xenon Lights** - Custom headlight colors
- 🏪 **Multiple Shop Types** - Cosmetic only, performance only, or both
- 👨‍🔧 **Job Discounts** - Mechanics get discounted rates
- 🛠️ **Admin Shop Management** - Create/edit/delete shops in-game
- 💾 **Handling Persistence** - Per-vehicle plate storage in database
- 🔐 **Permission System** - Role-based access control

---

## 📦 Dependencies

- `rpa-lib` (Required)
- `ox_lib` (Required)
- `oxmysql` (Required)
- `ox_target` or `qb-target` (Recommended)

---

## 📥 Installation

1. Download the [latest release](https://github.com/RP-Alpha/rpa-tuning/releases/latest)
2. Extract to your `resources` folder
3. Import the database:
   ```sql
   source sql/install.sql
   ```
4. Add to `server.cfg`:
   ```cfg
   ensure rpa-lib
   ensure rpa-tuning
   ```

---

## 🗄️ Database Setup

Run the SQL file to create:
- `rpa_tuning_shops` - Shop locations and settings
- `rpa_vehicle_handling` - Per-vehicle handling modifications

---

## ⚙️ Configuration

### Default Shops

```lua
Config.DefaultShops = {
    {
        id = 'lsc_burton',
        label = "Los Santos Customs - Burton",
        coords = vector3(-347.0, -133.0, 39.0),
        radius = 5.0,
        shopType = 'both',  -- 'cosmetic', 'performance', or 'both'
        blip = { sprite = 72, color = 5, scale = 0.8 }
    }
}
```

### Mechanic Permissions (Discounts)

```lua
Config.MechanicPermissions = {
    groups = {},
    jobs = { 'mechanic', 'tuner', 'bennys' },
    minGrade = 0,
    onDuty = true,
    discountPercent = 50  -- 50% off for mechanics
}
```

### Performance Tune Permissions

```lua
Config.PerformanceTunePermissions = {
    groups = { 'admin' },
    jobs = { 'mechanic', 'tuner' },
    minGrade = 2,  -- Only grade 2+ mechanics
    onDuty = true
}
```

### Tunable Handling Properties

| Property | Description | Range |
|----------|-------------|-------|
| `fInitialDriveForce` | Acceleration power | 0.1 - 2.0 |
| `fBrakeForce` | Braking power | 0.5 - 3.0 |
| `fTractionCurveMax` | High-speed grip | 1.0 - 3.5 |
| `fTractionCurveMin` | Low-speed grip | 1.0 - 3.0 |
| `fSuspensionForce` | Suspension stiffness | 1.0 - 5.0 |
| `fSuspensionReboundDamp` | Rebound damping | 0.5 - 3.0 |
| `fDriveBiasFront` | AWD bias (0=RWD, 1=FWD) | 0.0 - 1.0 |
| `nInitialDriveGears` | Number of gears | 1 - 8 |

---

## ⌨️ Commands

| Command | Description |
|---------|-------------|
| `/tuningadmin` | Open admin shop management menu |

---

## 🔐 Permissions

- **Admin** - Manage shops, set pricing
- **Mechanic** - Access discounted rates
- **Performance Tuner** - Access handling modifications

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

<div align="center">
  <sub>Built with ❤️ by <a href="https://github.com/RP-Alpha">RP-Alpha</a></sub>
</div>
