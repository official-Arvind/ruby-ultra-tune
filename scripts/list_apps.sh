#!/system/bin/sh
# ==============================================================================
# Ruby Ultra Tune v3.0 — App List Helper
# Outputs installed packages (UID >= 10000), bypassing APatch PM visibility
# ==============================================================================

cat /data/system/packages.list | while read pkg uid rest; do
    if [ "$uid" -ge 10000 ]; then
        echo "$pkg"
    fi
done | sort
