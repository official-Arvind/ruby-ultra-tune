# Ruby Ultra Performance & Hotspot Thermal Nuker

An advanced kernel, scheduler, and thermal tuning module engineered specifically for the **Redmi Note 12 Pro 5G / Pro+ 5G (`ruby` / `rubypro`)** running MediaTek Dimensity 1080 (`MT6877`) on HyperOS / MIUI.

Developed by **Arvind Ji**.

---

## Features

- **Nukes Hotspot Overheat Shutdowns:**
  - Disables aggressive `mi_thermald` triggers that forcibly shut off Wi-Fi Hotspot (`ap0`) when the device warms up.
  - Locks virtual thermal states and overrides Android framework hotspot protection settings so tethering stays on indefinitely.

- **Unlocks MediaTek Dimensity 1080 (MT6877) CPU Throttle:**
  - Disables MTK PPM (Process Power Manager) thermal policy `[4]` and power throttling policy `[3]`.
  - Prevents the Big Cortex-A78 performance cores (CPU 6 & 7) from being throttled down to 600 MHz under heavy use.
  - Keeps all 8 cores online and sets responsive frequency floors (Little: 1.05 GHz, Big: 1.04 GHz) to eliminate UI jitters and micro-stutters.

- **Governor & Scheduler Tuning:**
  - Schedutil `up_rate_limit_us` set to `0` for instantaneous frequency ramp on touch and app launches.
  - Energy Aware Scheduling (EAS) fine-tuned for smooth 120Hz frame pacing.

- **Storage & VM Memory Optimization:**
  - Internal UFS storage I/O set to `deadline` scheduler with `512 KB` read-ahead.
  - Tuned `vm.swappiness=60` and `vm.vfs_cache_pressure=50` to keep active apps cached in memory without kswapd thrashing.

- **Lightweight Watchdog:**
  - Self-healing background service ensures PPM policies and CPU frequencies remain unlocked without touching display drivers or battery calibration.

---

## Compatibility

- **Device:** Redmi Note 12 Pro 5G / Redmi Note 12 Pro+ 5G (`ruby` / `rubypro`)
- **Chipset:** MediaTek Dimensity 1080 (`MT6877`)
- **OS:** Xiaomi HyperOS 1.0 / 2.0 or MIUI 14 (Android 12 / 13 / 14)
- **Root Solution:** APatch, KernelSU, or Magisk

---

## Installation

### Method 1: Flashable Zip
1. Download the latest `ruby_ultra_tune.zip` from Releases.
2. Open APatch / KernelSU / Magisk app.
3. Go to the Modules tab, tap **Install from storage**, select the zip, and reboot.

### Method 2: Manual Install
1. Copy the repository files into `/data/adb/modules/ruby_ultra_tune/`:
   ```bash
   su
   mkdir -p /data/adb/modules/ruby_ultra_tune
   cp module.prop service.sh system.prop /data/adb/modules/ruby_ultra_tune/
   chmod 755 /data/adb/modules/ruby_ultra_tune/service.sh
   chmod 644 /data/adb/modules/ruby_ultra_tune/module.prop /data/adb/modules/ruby_ultra_tune/system.prop
   ```
2. Reboot your device.

---

## Author

- **Arvind Ji**
