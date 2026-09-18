#!/system/bin/sh
# ==============================================================================
# Ruby Ultra Tune v3.0 — App List Helper
# ==============================================================================

# Output all installed packages on a single comma-separated line.
# Using /data/data completely bypasses Android 11+ Package Visibility (pm list)
# and works natively without requiring 'su' or 'nsenter'.

ls -1 /data/data 2>/dev/null | grep "\." | while read pkg; do
    echo -n "$pkg,"
done
echo ""
