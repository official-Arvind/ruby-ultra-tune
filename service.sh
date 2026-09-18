#!/system/bin/sh
# ==============================================================================
# Ruby Ultra Tune v3.0 — Flagship Performance Engine
# Author: Arvind Ji
# Device: Redmi Note 12 Pro 5G (ruby) — MT6877 Dimensity 1080
# ==============================================================================
MODDIR=${0%/*}

# Wait for system boot
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 2
done

sleep 5

# ==============================================================================
# 1. HOTSPOT OVERHEAT SHUTDOWN PREVENTION
# ==============================================================================
stop mi_thermald 2>/dev/null
setprop ctl.stop mi_thermald 2>/dev/null

# Prevent userspace thermal daemon hotspot cutoffs while preserving kernel hardware protection
setprop persist.sys.thermal.mitigation 0 2>/dev/null
setprop persist.vendor.thermal.config "" 2>/dev/null

# Allow high-performance PPM scaling while keeping emergency thermal trip points intact
chmod 666 /proc/ppm/policy_status 2>/dev/null
echo "3 0" > /proc/ppm/policy_status 2>/dev/null  # Disable power throttling cap
echo "9 1" > /proc/ppm/policy_status 2>/dev/null  # Enable system boost policy

# Hotspot protection settings
settings put global hotspot_thermal_protect 0 2>/dev/null
settings put system wifi_ap_emergency_shut_down 0 2>/dev/null
settings put global wifi_ap_emergency_shut_down 0 2>/dev/null
settings put system softap_auto_off 0 2>/dev/null
settings put global softap_auto_off 0 2>/dev/null

# ==============================================================================
# 2. CPU & GOVERNOR — JITTER-FREE TUNING
# ==============================================================================
for c in 0 1 2 3 4 5 6 7; do
    echo 1 > /sys/devices/system/cpu/cpu$c/online 2>/dev/null
done

# Schedutil: instant ramp up, 40ms hold to prevent scroll flick jitters
echo 0 > /sys/devices/system/cpu/cpufreq/schedutil/up_rate_limit_us 2>/dev/null
echo 40000 > /sys/devices/system/cpu/cpufreq/schedutil/down_rate_limit_us 2>/dev/null

# EAS & Scheduler Core
echo 1 > /proc/sys/kernel/sched_energy_aware 2>/dev/null
echo 0 > /proc/sys/kernel/sched_child_runs_first 2>/dev/null
echo 0 > /proc/sys/kernel/sched_schedstats 2>/dev/null

# Scheduler Latency Tuning — reduce preemption delay for smoother UI
echo 1500000 > /proc/sys/kernel/sched_min_granularity_ns 2>/dev/null
echo 1500000 > /proc/sys/kernel/sched_wakeup_granularity_ns 2>/dev/null
echo 5000000 > /proc/sys/kernel/sched_migration_cost_ns 2>/dev/null
echo 8 > /proc/sys/kernel/sched_nr_migrate 2>/dev/null

# Reduce perf tracing overhead
echo 5 > /proc/sys/kernel/perf_cpu_time_max_percent 2>/dev/null

# Snappy 120Hz Animation Curves
settings put global window_animation_scale 0.8 2>/dev/null
settings put global transition_animation_scale 0.8 2>/dev/null
settings put global animator_duration_scale 0.8 2>/dev/null

# ==============================================================================
# 3. TOUCH IRQ AFFINITY — PIN TO BIG CORES
# ==============================================================================
TOUCH_IRQ=$(grep -iE "fts_ts|goodix|focaltech|synaptics|mtk-tpd" /proc/interrupts 2>/dev/null | head -1 | awk '{print $1}' | tr -d ':')
if [ -n "$TOUCH_IRQ" ]; then
    echo 6-7 > /proc/irq/$TOUCH_IRQ/smp_affinity_list 2>/dev/null
fi

# ==============================================================================
# 4. GPU TUNING — MTK GED (Mali-G68 MC4)
# ==============================================================================
# Set GPU floor to OPP 30 (509 MHz) for smooth daily UI
echo 509000 > /sys/module/ged/parameters/gpu_cust_boost_freq 2>/dev/null
# Keep GPU ceiling at max (950 MHz)
echo 950000 > /sys/module/ged/parameters/gpu_cust_upbound_freq 2>/dev/null
# Enable GPU boost subsystems
echo 1 > /sys/module/ged/parameters/ged_boost_enable 2>/dev/null
echo 1 > /sys/module/ged/parameters/enable_gpu_boost 2>/dev/null
echo 1 > /sys/module/ged/parameters/gpu_dvfs_enable 2>/dev/null
# More responsive GPU DVFS threshold (scale up earlier)
echo 60 > /sys/module/ged/parameters/g_fb_dvfs_threshold 2>/dev/null
# Smart boost for frame pacing
echo 1 > /sys/module/ged/parameters/ged_smart_boost 2>/dev/null

# ==============================================================================
# 5. CPUSETS & SCHEDTUNE (MULTITASKING & BACKGROUND APP FIX)
# ==============================================================================
echo 0-3 > /dev/cpuset/background/cpus 2>/dev/null
echo 0-5 > /dev/cpuset/system-background/cpus 2>/dev/null
echo 0-7 > /dev/cpuset/top-app/cpus 2>/dev/null
echo 0-7 > /dev/cpuset/foreground/cpus 2>/dev/null

echo 1 > /proc/perfmgr/syslimiter/syslimiter_force_disable 2>/dev/null

if [ -d "/proc/perfmgr/boost_ctrl/eas_ctrl" ]; then
    echo 120 > /proc/perfmgr/boost_ctrl/eas_ctrl/perf_ta_uclamp_min 2>/dev/null
    echo 60 > /proc/perfmgr/boost_ctrl/eas_ctrl/perf_fg_uclamp_min 2>/dev/null
    echo 10 > /proc/perfmgr/boost_ctrl/eas_ctrl/perfserv_ta_boost 2>/dev/null
    echo 1 > /proc/perfmgr/boost_ctrl/eas_ctrl/sched_big_task_rotation 2>/dev/null
fi

# ==============================================================================
# 6. STORAGE & F2FS I/O JITTER PREVENTION
# ==============================================================================
# UFS I/O scheduler tuning
for s in /sys/block/sd*/queue/scheduler; do
    [ -f "$s" ] && echo deadline > "$s" 2>/dev/null
done
for q in /sys/block/sd*/queue/read_ahead_kb; do
    [ -f "$q" ] && echo 512 > "$q" 2>/dev/null
done
# Tune deadline scheduler for low latency
for d in /sys/block/sd*/queue/iosched; do
    if [ -d "$d" ]; then
        echo 1 > "$d/fifo_batch" 2>/dev/null
        echo 1 > "$d/writes_starved" 2>/dev/null
        echo 100 > "$d/read_expire" 2>/dev/null
        echo 1000 > "$d/write_expire" 2>/dev/null
    fi
done

# F2FS: idle GC, batched writes, no iostat overhead — ALL partitions
for f in /sys/fs/f2fs/dm-*; do
    if [ -d "$f" ]; then
        echo 0 > "$f/iostat_enable" 2>/dev/null
        echo 60 > "$f/cp_interval" 2>/dev/null
        echo 16 > "$f/min_fsync_blocks" 2>/dev/null
        echo 1 > "$f/gc_idle" 2>/dev/null
    fi
done

# ==============================================================================
# 7. VM & MEMORY TUNING
# ==============================================================================
sysctl -w vm.swappiness=100 2>/dev/null
sysctl -w vm.vfs_cache_pressure=50 2>/dev/null
sysctl -w vm.dirty_ratio=20 2>/dev/null
sysctl -w vm.dirty_background_ratio=5 2>/dev/null
sysctl -w vm.dirty_expire_centisecs=1500 2>/dev/null
sysctl -w vm.dirty_writeback_centisecs=500 2>/dev/null
sysctl -w vm.watermark_scale_factor=120 2>/dev/null
sysctl -w vm.watermark_boost_factor=0 2>/dev/null
sysctl -w vm.stat_interval=10 2>/dev/null
echo 0 > /proc/sys/vm/page-cluster 2>/dev/null
# Compact ZRAM on boot
echo 1 > /sys/block/zram0/compact 2>/dev/null

# ==============================================================================
# 8. NETWORK STACK — LOW LATENCY GAMING
# ==============================================================================
# Disable slow start after idle (critical for gaming reconnections)
sysctl -w net.ipv4.tcp_slow_start_after_idle=0 2>/dev/null
# TCP Fast Open (client + server)
sysctl -w net.ipv4.tcp_fastopen=3 2>/dev/null
# Fresh TCP metrics for every connection
sysctl -w net.ipv4.tcp_no_metrics_save=1 2>/dev/null
# Send small packets immediately
sysctl -w net.ipv4.tcp_autocorking=0 2>/dev/null
# Anti-bufferbloat: flush send queue promptly
sysctl -w net.ipv4.tcp_notsent_lowat=16384 2>/dev/null
# Enable MTU probing for path optimization
sysctl -w net.ipv4.tcp_mtu_probing=1 2>/dev/null
# Disable ECN (some game servers drop ECN packets)
sysctl -w net.ipv4.tcp_ecn=0 2>/dev/null
# Socket buffer tuning
sysctl -w net.core.rmem_max=8388608 2>/dev/null
sysctl -w net.core.wmem_max=8388608 2>/dev/null
sysctl -w net.core.somaxconn=4096 2>/dev/null
sysctl -w net.core.netdev_max_backlog=5000 2>/dev/null

# ==============================================================================
# 9. MULTITASKING UNLOCK
# ==============================================================================
/system/bin/device_config put activity_manager max_phantom_processes 2147483647 2>/dev/null
setprop persist.sys.fflag.override.settings_enable_monitor_phantom_procs false 2>/dev/null

# ==============================================================================
# 10. GAME MODE DAEMON
# ==============================================================================
# Create config directory
mkdir -p "$MODDIR/config"
[ ! -f "$MODDIR/config/games.list" ] && touch "$MODDIR/config/games.list"
[ ! -f "$MODDIR/config/donotkill.list" ] && touch "$MODDIR/config/donotkill.list"

# Kill any previous daemon instance
OLD_PID=$(cat "$MODDIR/config/daemon.pid" 2>/dev/null)
[ -n "$OLD_PID" ] && kill "$OLD_PID" 2>/dev/null

# Launch game mode daemon in background
nohup sh "$MODDIR/scripts/gamemode_daemon.sh" > /dev/null 2>&1 &

# ==============================================================================
# 11. BACKGROUND WATCHDOG
# ==============================================================================
nohup sh -c '
GM_STATE="'"$MODDIR"'/config/gamemode_active"
while true; do
    sleep 10
    # Re-kill mi_thermald (respawns via init)
    stop mi_thermald 2>/dev/null
    # Re-disable PPM thermal policies
    echo "4 0" > /proc/ppm/policy_status 2>/dev/null
    echo "3 0" > /proc/ppm/policy_status 2>/dev/null
    echo "9 0" > /proc/ppm/policy_status 2>/dev/null
    # Re-disable SysLimiter
    echo 1 > /proc/perfmgr/syslimiter/syslimiter_force_disable 2>/dev/null
    # Check if game mode is active — respect gaming profiles
    IS_GAMING=$(cat "$GM_STATE" 2>/dev/null)
    if [ "$IS_GAMING" = "1" ]; then
        # Game mode: keep aggressive boost
        echo 50000 > /sys/devices/system/cpu/cpufreq/schedutil/down_rate_limit_us 2>/dev/null
        echo 300 > /proc/perfmgr/boost_ctrl/eas_ctrl/perf_ta_uclamp_min 2>/dev/null
        echo 50 > /proc/perfmgr/boost_ctrl/eas_ctrl/perfserv_ta_boost 2>/dev/null
        echo 890000 > /sys/module/ged/parameters/gpu_cust_boost_freq 2>/dev/null
    else
        # Normal mode
        echo 40000 > /sys/devices/system/cpu/cpufreq/schedutil/down_rate_limit_us 2>/dev/null
        echo 120 > /proc/perfmgr/boost_ctrl/eas_ctrl/perf_ta_uclamp_min 2>/dev/null
        echo 60 > /proc/perfmgr/boost_ctrl/eas_ctrl/perf_fg_uclamp_min 2>/dev/null
        echo 10 > /proc/perfmgr/boost_ctrl/eas_ctrl/perfserv_ta_boost 2>/dev/null
        echo 509000 > /sys/module/ged/parameters/gpu_cust_boost_freq 2>/dev/null
    fi
    echo 1 > /sys/module/ged/parameters/ged_boost_enable 2>/dev/null
    # Keep big cores online
    for c in 6 7; do
        if [ "$(cat /sys/devices/system/cpu/cpu$c/online 2>/dev/null)" = "0" ]; then
            echo 1 > /sys/devices/system/cpu/cpu$c/online 2>/dev/null
        fi
    done
done
' > /dev/null 2>&1 &

exit 0
