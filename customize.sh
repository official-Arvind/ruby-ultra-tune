#!/system/bin/sh
# Ruby Ultra Tune v3.0 Installer

SKIPUNZIP=0

ui_print ""
ui_print "╔══════════════════════════════════════════╗"
ui_print "║       Ruby Ultra Tune v3.0               ║"
ui_print "║       by Arvind Ji                        ║"
ui_print "╠══════════════════════════════════════════╣"
ui_print "║  Redmi Note 12 Pro 5G (MT6877)           ║"
ui_print "║                                          ║"
ui_print "║  ✦ Flagship Performance Engine           ║"
ui_print "║  ✦ Auto Game Mode + WebGUI               ║"
ui_print "║  ✦ GPU / CPU / Network Tuning            ║"
ui_print "║  ✦ Touch IRQ Big-Core Affinity           ║"
ui_print "║  ✦ Hotspot Thermal Nuker                 ║"
ui_print "╚══════════════════════════════════════════╝"
ui_print ""

# Preserve existing config if upgrading
if [ -d "/data/adb/modules/ruby_ultra_tune/config" ]; then
    ui_print "  [*] Preserving existing Game Mode config..."
    cp -rf /data/adb/modules/ruby_ultra_tune/config "$TMPDIR/rut_config_backup" 2>/dev/null
fi

# Set permissions
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm_recursive "$MODPATH/scripts" 0 0 0755 0755
set_perm_recursive "$MODPATH/webroot" 0 0 0755 0644

# Create config dir
mkdir -p "$MODPATH/config"

# Restore config if upgrading
if [ -d "$TMPDIR/rut_config_backup" ]; then
    cp -rf "$TMPDIR/rut_config_backup/"* "$MODPATH/config/" 2>/dev/null
    ui_print "  [*] Config restored."
fi

# Ensure config files exist
[ ! -f "$MODPATH/config/games.list" ] && touch "$MODPATH/config/games.list"
[ ! -f "$MODPATH/config/donotkill.list" ] && touch "$MODPATH/config/donotkill.list"

ui_print ""
ui_print "  [✓] Installation complete!"
ui_print "  [i] Open APatch → Modules → Ruby Ultra Tune"
ui_print "  [i] Tap the WebUI button to manage Game Mode."
ui_print ""
