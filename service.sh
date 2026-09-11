#!/system/bin/sh
MODDIR=${0%/*}

# Wait for system boot
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 2
done

sleep 5

# 1. Hotspot Overheat Shutdown Prevention
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

# 2. CPU & Governor Tuning
for c in 0 1 2 3 4 5 6 7; do
    echo 1 > /sys/devices/system/cpu/cpu$c/online 2>/dev/null
done

# Frequency floors/ceilings
echo 1053000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq 2>/dev/null
echo 2000000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq 2>/dev/null
echo 1040000 > /sys/devices/system/cpu/cpufreq/policy6/scaling_min_freq 2>/dev/null
echo 2600000 > /sys/devices/system/cpu/cpufreq/policy6/scaling_max_freq 2>/dev/null

# Schedutil rate limits
echo 0 > /sys/devices/system/cpu/cpufreq/schedutil/up_rate_limit_us 2>/dev/null
echo 20000 > /sys/devices/system/cpu/cpufreq/schedutil/down_rate_limit_us 2>/dev/null

# EAS & Scheduler
echo 1 > /proc/sys/kernel/sched_energy_aware 2>/dev/null
echo 0 > /proc/sys/kernel/sched_child_runs_first 2>/dev/null

# Storage & VM
for s in /sys/block/sd*/queue/scheduler; do
    [ -f "$s" ] && echo deadline > "$s" 2>/dev/null
done
for q in /sys/block/sd*/queue/read_ahead_kb; do
    [ -f "$q" ] && echo 512 > "$q" 2>/dev/null
done

sysctl -w vm.swappiness=60 2>/dev/null
sysctl -w vm.vfs_cache_pressure=50 2>/dev/null

# Background watchdog (CPU & PPM only - NEVER touch display, screen, or brightness)
nohup sh -c '
while true; do
    sleep 10
    stop mi_thermald 2>/dev/null
    echo "4 0" > /proc/ppm/policy_status 2>/dev/null
    echo "3 0" > /proc/ppm/policy_status 2>/dev/null
    echo "9 0" > /proc/ppm/policy_status 2>/dev/null
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
