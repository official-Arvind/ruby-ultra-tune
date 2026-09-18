#!/system/bin/sh
# ==============================================================================
# Ruby Ultra Tune v3.0 — Auto Game Mode Daemon
# Author: Arvind Ji
# Detects game launches, kills background apps, boosts CPU/GPU
# ==============================================================================

MODDIR="/data/adb/modules/ruby_ultra_tune"
CONFIG_DIR="$MODDIR/config"
GAMES_LIST="$CONFIG_DIR/games.list"
DNK_LIST="$CONFIG_DIR/donotkill.list"
STATE_FILE="$CONFIG_DIR/gamemode_active"
LOG_FILE="$CONFIG_DIR/gamemode.log"

ESSENTIAL_PACKAGES="
system_server
com.android.systemui
com.android.phone
com.android.bluetooth
com.android.providers.telephony
com.android.providers.media
com.android.providers.contacts
com.android.providers.calendar
com.android.providers.downloads
com.android.providers.settings
com.google.android.inputmethod.latin
com.google.android.gms
com.google.android.gsf
com.google.android.ext.services
com.miui.powerkeeper
com.xiaomi.joyose
com.miui.home
com.miui.securitycenter
com.miui.miwallpaper
com.android.networkstack
com.android.networkstack.tethering
com.android.nfc
com.android.se
com.android.settings
com.android.shell
com.android.ims.rcsservice
com.mediatek.ims
me.bmax.apatch
com.miui.securitycenter.remote
com.xiaomi.mi_connect_service
com.miui.misightservice
com.android.externalstorage
com.xiaomi.aicr
"

mkdir -p "$CONFIG_DIR"
[ ! -f "$GAMES_LIST" ] && touch "$GAMES_LIST"
[ ! -f "$DNK_LIST" ] && touch "$DNK_LIST"
echo 0 > "$STATE_FILE"

GAME_MODE_ACTIVE=0
CURRENT_GAME=""

log() {
    echo "[$(date '+%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    local lines
    lines=$(wc -l < "$LOG_FILE" 2>/dev/null)
    [ "$lines" -gt 500 ] && tail -200 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
}

notify() {
    su 2000 -c "cmd notification post -S bigtext -t \"$1\" ruby_gamemode \"$2\"" 2>/dev/null
}

notify_cancel() {
    cmd notification cancel ruby_gamemode 2>/dev/null
}

is_game() {
    grep -qxF "$1" "$GAMES_LIST" 2>/dev/null
}

is_protected() {
    local pkg="$1"
    echo "$ESSENTIAL_PACKAGES" | grep -qxF "$pkg" && return 0
    grep -qxF "$pkg" "$DNK_LIST" 2>/dev/null && return 0
    local uid
    uid=$(dumpsys package "$pkg" 2>/dev/null | sed -n 's/.*userId=\([0-9]*\).*/\1/p' | head -1)
    [ -n "$uid" ] && [ "$uid" -lt 10000 ] && return 0
    return 1
}

get_top_package() {
    # Modern ultra-light foreground app check (Auditor Standard)
    # Avoids heavy IPC dumpsys activity parsing
    local raw
    raw=$(dumpsys window 2>/dev/null | grep -i mcurrentfocus | head -1)
    [ -z "$raw" ] && return
    echo "$raw" | sed 's/.*u0 \([^/]*\).*/\1/'
}

activate_game_mode() {
    local game_pkg="$1"
    log "GAME MODE ACTIVATING for: $game_pkg"
    GAME_MODE_ACTIVE=1
    CURRENT_GAME="$game_pkg"
    echo 1 > "$STATE_FILE"
    echo "$game_pkg" > "$CONFIG_DIR/current_game"

    # 1. Restrict background cpuset
    echo 0-1 > /dev/cpuset/background/cpus 2>/dev/null
    echo 0-3 > /dev/cpuset/system-background/cpus 2>/dev/null

    # 3. GPU boost to 890 MHz
    echo 890000 > /sys/module/ged/parameters/gpu_cust_boost_freq 2>/dev/null
    echo 1 > /sys/module/ged/parameters/gx_game_mode 2>/dev/null
    echo 1 > /sys/module/ged/parameters/boost_gpu_enable 2>/dev/null
    echo 1 > /sys/module/ged/parameters/gx_boost_on 2>/dev/null

    # 4. EAS maximum boost
    echo 300 > /proc/perfmgr/boost_ctrl/eas_ctrl/perf_ta_uclamp_min 2>/dev/null
    echo 50 > /proc/perfmgr/boost_ctrl/eas_ctrl/perfserv_ta_boost 2>/dev/null

    # 5. Sustain CPU frequency
    echo 50000 > /sys/devices/system/cpu/cpufreq/schedutil/down_rate_limit_us 2>/dev/null

    # 6. Drop caches and compact ZRAM
    echo 3 > /proc/sys/vm/drop_caches 2>/dev/null
    echo 1 > /sys/block/zram0/compact 2>/dev/null

    # 7. Safe Zero-IPC Background App Killing
    local killed=0
    for uid in $(ps -A -o UID 2>/dev/null | grep -E '^[0-9]+$' | awk '$1 >= 10000' | sort -u); do
        local pkg=$(grep -m1 " $uid " /data/system/packages.list 2>/dev/null | awk '{print $1}')
        [ -z "$pkg" ] && continue
        [ "$pkg" = "$game_pkg" ] && continue
        is_protected "$pkg" && continue
        
        am force-stop "$pkg" 2>/dev/null
        killed=$((killed + 1))
    done

    # 8. Second cache drop
    sleep 1
    echo 3 > /proc/sys/vm/drop_caches 2>/dev/null

    local ram_mb
    ram_mb=$(grep MemAvailable /proc/meminfo | awk '{print int($2/1024)}')

    log "GAME MODE ACTIVE — killed $killed apps, GPU@890MHz, RAM=${ram_mb}MB free"

    # 9. Show notification
    notify "⚡ Game Mode ON" "GPU boosted to 890 MHz
$killed background apps cleared
${ram_mb}MB RAM available for gaming"
}

deactivate_game_mode() {
    log "GAME MODE DEACTIVATING"
    GAME_MODE_ACTIVE=0
    CURRENT_GAME=""
    echo 0 > "$STATE_FILE"
    rm -f "$CONFIG_DIR/current_game"

    echo 0-3 > /dev/cpuset/background/cpus 2>/dev/null
    echo 0-5 > /dev/cpuset/system-background/cpus 2>/dev/null

    echo 509000 > /sys/module/ged/parameters/gpu_cust_boost_freq 2>/dev/null
    echo 0 > /sys/module/ged/parameters/gx_game_mode 2>/dev/null
    echo 0 > /sys/module/ged/parameters/boost_gpu_enable 2>/dev/null
    echo 0 > /sys/module/ged/parameters/gx_boost_on 2>/dev/null

    echo 120 > /proc/perfmgr/boost_ctrl/eas_ctrl/perf_ta_uclamp_min 2>/dev/null
    echo 10 > /proc/perfmgr/boost_ctrl/eas_ctrl/perfserv_ta_boost 2>/dev/null

    echo 40000 > /sys/devices/system/cpu/cpufreq/schedutil/down_rate_limit_us 2>/dev/null

    log "NORMAL MODE RESTORED"

    notify_cancel
    notify "🔄 Normal Mode" "Performance profile restored
GPU floor: 509 MHz • SchedBoost: 10"
    # Auto-dismiss after 5 seconds
    sleep 5
    notify_cancel
}

# Kill previous daemon
OLD_PID=$(cat "$CONFIG_DIR/daemon.pid" 2>/dev/null)
if [ -n "$OLD_PID" ] && [ "$OLD_PID" != "$$" ]; then
    kill "$OLD_PID" 2>/dev/null
    sleep 1
fi

echo $$ > "$CONFIG_DIR/daemon.pid"
log "Daemon started (PID: $$)"

# ======================== MAIN LOOP ========================
while true; do
    sleep 2

    # Battery Saving: Pause polling when screen is off (Doze mode)
    if dumpsys power 2>/dev/null | grep -q "mWakefulness=Asleep"; then
        sleep 5
        continue
    fi

    TOP_PKG=$(get_top_package)
    [ -z "$TOP_PKG" ] && continue

    if [ "$GAME_MODE_ACTIVE" = "0" ]; then
        if is_game "$TOP_PKG"; then
            activate_game_mode "$TOP_PKG"
        fi
    else
        if [ "$TOP_PKG" != "$CURRENT_GAME" ]; then
            sleep 3
            TOP_PKG2=$(get_top_package)
            if [ -z "$TOP_PKG2" ] || [ "$TOP_PKG2" = "$CURRENT_GAME" ]; then
                continue
            fi
            if ! is_game "$TOP_PKG2"; then
                deactivate_game_mode
            else
                deactivate_game_mode
                sleep 1
                activate_game_mode "$TOP_PKG2"
            fi
        else
            # Continuous Enforcement: Check every 5 seconds to prevent battery drain
            sleep 3
            for uid in $(ps -A -o UID 2>/dev/null | grep -E '^[0-9]+$' | awk '$1 >= 10000' | sort -u); do
                local pkg=$(grep -m1 " $uid " /data/system/packages.list 2>/dev/null | awk '{print $1}')
                [ -z "$pkg" ] && continue
                [ "$pkg" = "$CURRENT_GAME" ] && continue
                is_protected "$pkg" && continue
                
                am force-stop "$pkg" 2>/dev/null
            done
        fi
    fi
done
