#!/system/bin/sh
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

if [ -f /sys/class/thermal/thermal_message/temp_state ]; then
    chmod 666 /sys/class/thermal/thermal_message/temp_state 2>/dev/null
    echo 0 > /sys/class/thermal/thermal_message/temp_state
    chmod 444 /sys/class/thermal/thermal_message/temp_state 2>/dev/null
    
    mkdir -p /data/adb/tune
    echo 0 > /data/adb/tune/zero_temp_state
    chmod 444 /data/adb/tune/zero_temp_state
    mount --bind /data/adb/tune/zero_temp_state /sys/class/thermal/thermal_message/temp_state 2>/dev/null
fi

# MTK PPM Thermal & Power Capping Disable
chmod 666 /proc/ppm/policy_status 2>/dev/null
echo "4 0" > /proc/ppm/policy_status 2>/dev/null
echo "3 0" > /proc/ppm/policy_status 2>/dev/null
echo "9 0" > /proc/ppm/policy_status 2>/dev/null

# Hotspot protection settings
settings put global hotspot_thermal_protect 0 2>/dev/null
settings put system wifi_ap_emergency_shut_down 0 2>/dev/null
settings put global wifi_ap_emergency_shut_down 0 2>/dev/null
settings put system softap_auto_off 0 2>/dev/null
settings put global softap_auto_off 0 2>/dev/null

# ==============================================================================
# 2. CPU & GOVERNOR TUNING (FLAGSHIP RESPONSIVENESS)
# ==============================================================================
for c in 0 1 2 3 4 5 6 7; do
    echo 1 > /sys/devices/system/cpu/cpu$c/online 2>/dev/null
done

# Frequency floors & ceilings
echo 1053000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq 2>/dev/null
echo 2000000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq 2>/dev/null
echo 1040000 > /sys/devices/system/cpu/cpufreq/policy6/scaling_min_freq 2>/dev/null
echo 2600000 > /sys/devices/system/cpu/cpufreq/policy6/scaling_max_freq 2>/dev/null

# Schedutil rate limits (instantaneous ramp on touch)
echo 0 > /sys/devices/system/cpu/cpufreq/schedutil/up_rate_limit_us 2>/dev/null
echo 20000 > /sys/devices/system/cpu/cpufreq/schedutil/down_rate_limit_us 2>/dev/null

# EAS & Scheduler
echo 1 > /proc/sys/kernel/sched_energy_aware 2>/dev/null
echo 0 > /proc/sys/kernel/sched_child_runs_first 2>/dev/null
echo 0 > /proc/sys/kernel/sched_schedstats 2>/dev/null

# ==============================================================================
# 3. CPUSETS & SCHEDTUNE (MULTITASKING & BACKGROUND APP FIX)
# ==============================================================================
# Expand background tasks to cores 0-3 (prevents 0-2 bottleneck)
echo 0-3 > /dev/cpuset/background/cpus 2>/dev/null
# Expand system-background to cores 0-5 (all little cores)
echo 0-5 > /dev/cpuset/system-background/cpus 2>/dev/null
# Keep top-app and foreground unconstrained (0-7)
echo 0-7 > /dev/cpuset/top-app/cpus 2>/dev/null
echo 0-7 > /dev/cpuset/foreground/cpus 2>/dev/null

# Top-App & Foreground SchedTune Boost
echo 10 > /dev/stune/top-app/schedtune.boost 2>/dev/null
echo 1 > /dev/stune/top-app/schedtune.prefer_idle 2>/dev/null
echo 5 > /dev/stune/foreground/schedtune.boost 2>/dev/null
echo 0 > /dev/stune/background/schedtune.boost 2>/dev/null

# Disable MediaTek SysLimiter
echo 1 > /proc/perfmgr/syslimiter/syslimiter_force_disable 2>/dev/null

# MTK EAS Boost Controls for Top-App & Foreground
if [ -d "/proc/perfmgr/boost_ctrl/eas_ctrl" ]; then
    echo 120 > /proc/perfmgr/boost_ctrl/eas_ctrl/perf_ta_uclamp_min 2>/dev/null
    echo 60 > /proc/perfmgr/boost_ctrl/eas_ctrl/perf_fg_uclamp_min 2>/dev/null
    echo 10 > /proc/perfmgr/boost_ctrl/eas_ctrl/perfserv_ta_boost 2>/dev/null
    echo 1 > /proc/perfmgr/boost_ctrl/eas_ctrl/sched_big_task_rotation 2>/dev/null
fi

# ==============================================================================
# 4. STORAGE & ADVANCED VM MEMORY MANAGEMENT
# ==============================================================================
for s in /sys/block/sd*/queue/scheduler; do
    [ -f "$s" ] && echo deadline > "$s" 2>/dev/null
done
for q in /sys/block/sd*/queue/read_ahead_kb; do
    [ -f "$q" ] && echo 512 > "$q" 2>/dev/null
done

# VM Swappiness & Async Reclaim Tuning (Keeps page caches hot, prevents cold app reloads)
sysctl -w vm.swappiness=100 2>/dev/null
sysctl -w vm.vfs_cache_pressure=50 2>/dev/null
sysctl -w vm.dirty_ratio=20 2>/dev/null
sysctl -w vm.dirty_background_ratio=5 2>/dev/null
sysctl -w vm.watermark_scale_factor=120 2>/dev/null
sysctl -w vm.watermark_boost_factor=0 2>/dev/null
sysctl -w vm.stat_interval=10 2>/dev/null

# Unlock Android Multitasking (Disable Phantom Process Killer)
/system/bin/device_config put activity_manager max_phantom_processes 2147483647 2>/dev/null
setprop persist.sys.fflag.override.settings_enable_monitor_phantom_procs false 2>/dev/null

# ==============================================================================
# 5. BACKGROUND WATCHDOG (CPU & PPM ONLY - NEVER TOUCH DISPLAY/BRIGHTNESS)
# ==============================================================================
nohup sh -c '
while true; do
    sleep 10
    stop mi_thermald 2>/dev/null
    echo "4 0" > /proc/ppm/policy_status 2>/dev/null
    echo "3 0" > /proc/ppm/policy_status 2>/dev/null
    echo "9 0" > /proc/ppm/policy_status 2>/dev/null
    echo 1 > /proc/perfmgr/syslimiter/syslimiter_force_disable 2>/dev/null
    echo 2600000 > /sys/devices/system/cpu/cpufreq/policy6/scaling_max_freq 2>/dev/null
    echo 2000000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq 2>/dev/null
    for c in 6 7; do
        if [ "$(cat /sys/devices/system/cpu/cpu$c/online 2>/dev/null)" = "0" ]; then
            echo 1 > /sys/devices/system/cpu/cpu$c/online 2>/dev/null
        fi
    done
done
' >/dev/null 2>&1 &

exit 0
