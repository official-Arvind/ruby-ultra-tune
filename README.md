# Ruby Ultra Performance & Hotspot Thermal Nuker

An advanced flagship-grade kernel, scheduler, and thermal tuning module engineered specifically for the **Redmi Note 12 Pro 5G / Pro+ 5G (`ruby` / `rubypro`)** running MediaTek Dimensity 1080 (`MT6877`) on HyperOS / MIUI.

Developed by **Arvind Ji**.

---

## Features

### 1. Flagship Multitasking & Background App Responsiveness (v2.1)
- **CPUSet Load Distribution:**
  - Expanded `background` cpuset from `0-2` to `0-3` and `system-background` to `0-5`.
  - Eliminates the severe 3-core bottleneck where background apps choke each other, ensuring instant switching between recent apps.
- **Top-App SchedTune & EAS Boosting:**
  - Configured `stune.boost=10` and `prefer_idle=1` for active foreground apps.
  - Injected MTK EAS capacity clamping (`perf_ta_uclamp_min=120`, `perfserv_ta_boost=10`) so app UI threads receive immediate placement on fast Cortex-A78 big cores without ramp lag.
- **Disabled MediaTek SysLimiter & Schedstats:**
  - Forces `/proc/perfmgr/syslimiter/syslimiter_force_disable` to `1` to eliminate MediaTek's artificial background task throttling.
  - Disables `/proc/sys/kernel/sched_schedstats` to eliminate context-switching profiling overhead.
- **Unlocked Background App Retention:**
  - Disables the Android 12/13/14 Phantom Process Killer (`max_phantom_processes=2147483647`), preventing Android from killing child background processes.

### 2. Intelligent Memory & Caching Optimization
- **High-Performance ZRAM Swappiness:**
  - Tuned `vm.swappiness=100` to compress stale anonymous memory into fast LZ4 ZRAM, keeping physical RAM free for executable file and asset page caches.
- **Asynchronous Memory Reclaim:**
  - Tuned `vm.watermark_scale_factor=120` so `kswapd0` reclaims memory proactively in the background, eliminating direct-reclaim frame drops.
  - Set `vm.vfs_cache_pressure=50` to keep filesystem and directory dentries hot in memory.

### 3. CPU Throttle Nuker (MediaTek Dimensity 1080)
- **Disabled MTK PPM Policies:**
  - Nukes MTK PPM thermal policy `[4]` and power throttling policy `[3]`.
  - Prevents the Big Cortex-A78 performance cores (CPU 6 & 7) from being capped to 600 MHz under heavy load.
- **Frequency Floors:**
  - Little Cluster (CPU 0–5): Locked minimum frequency of `1.05 GHz`.
  - Big Cluster (CPU 6–7): Locked minimum frequency of `1.04 GHz`.
  - Instantaneous Schedutil touch ramp (`up_rate_limit_us=0`).

### 4. Wi-Fi Hotspot Thermal Shutdown Nuker
- Stops aggressive `mi_thermald` triggers and permanently binds thermal state to `0`.
- Overrides Android framework tethering safety cutoffs so Wi-Fi Hotspot (`ap0`) stays active indefinitely even under maximum system load.

---

## Compatibility

- **Device:** Redmi Note 12 Pro 5G / Redmi Note 12 Pro+ 5G (`ruby` / `rubypro`)
- **Chipset:** MediaTek Dimensity 1080 (`MT6877`)
- **OS:** Xiaomi HyperOS 1.0 / 2.0 or MIUI 14 (Android 12 / 13 / 14)
- **Root Solution:** APatch, KernelSU, or Magisk

---

## Installation

### Method 1: Flashable Zip
1. Download `ruby_ultra_tune-v2.1.zip` from Releases.
2. Open APatch / KernelSU / Magisk app.
3. Go to Modules tab, tap **Install from storage**, select the zip, and reboot.

### Method 2: Manual Install
1. Copy files into `/data/adb/modules/ruby_ultra_tune/`:
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
