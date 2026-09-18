#!/system/bin/sh
# ==============================================================================
# Ruby Ultra Tune v3.0 — App List Helper
# Outputs installed 3rd-party packages, one per line: package_name
# Used by WebGUI to populate app selection lists
# ==============================================================================

# Use /system/bin/cmd for faster and more reliable package listing in root shells
/system/bin/cmd package list packages -3 2>/dev/null | sed 's/^package://' | sort
