# Ruby Ultra Tune

Flagship performance engine for **Redmi Note 12 Pro 5G** (ruby/rubypro) — MediaTek Dimensity 1080 (MT6877).

## Features

### Performance Engine
- **Thermal bypass** — Disables mi_thermald and MTK PPM thermal/power throttling
- **CPU tuning** — Schedutil instant ramp-up with 40ms hold, scheduler latency optimization
- **GPU tuning** — MTK GED boost floor at 509 MHz, smart boost, responsive DVFS threshold
- **Network stack** — TCP Fast Open, anti-bufferbloat, zero slow-start-after-idle
- **I/O optimization** — F2FS idle GC, batched writes, UFS deadline scheduler tuning
- **Memory tuning** — Aggressive ZRAM compaction, optimized dirty page writeback
- **Multitasking** — Expanded cpusets, phantom process killer disabled, EAS uclamp boost
- **Background watchdog** — Re-applies tunables every 10s to fight MTK PowerHAL resets

### Auto Game Mode
- Detects game launches automatically via activity monitoring
- Kills non-essential background apps to free RAM
- Boosts GPU to 890 MHz and CPU scheduling priority to maximum
- Restricts background processes to efficiency cores only
- Drops caches and compacts ZRAM before game starts
- Restores normal profile when you exit the game
- Configurable via built-in WebGUI

### WebGUI
- Dark Material You themed interface
- Accessible from APatch/KernelSU module manager
- Select games from your installed app list with icons
- Set "Do Not Kill" apps that stay alive during Game Mode
- Live system status: CPU/GPU frequencies, RAM, display Hz
- Quick actions: force Game Mode on/off
- Real-time daemon log viewer

## Requirements
- Redmi Note 12 Pro 5G (ruby/rubypro)
- APatch or KernelSU
- Android 14 (HyperOS 2.0)

## Installation
1. Download the latest release zip
2. Open APatch → Modules → Install from storage
3. Select the zip file
4. Reboot

Config is preserved across updates.

## WebGUI Access
After installation, open APatch → Modules → Ruby Ultra Tune → tap the **WebUI** button.

## Author
**Arvind Ji**

## License
MIT
