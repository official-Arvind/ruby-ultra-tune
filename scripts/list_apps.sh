#!/system/bin/sh
# ==============================================================================
# Ruby Ultra Tune v3.0 — App List Helper
# Outputs installed packages (UID >= 10000)
# ==============================================================================

# CRITICAL WORKAROUND: APatch's ksu.exec() bridge has a bug where it only
# returns the VERY LAST LINE of stdout.
# We MUST return all packages on a single line separated by commas!

nsenter -t 1 -m cat /data/system/packages.list 2>/dev/null | while read pkg uid rest; do
    if [ "$uid" -ge 10000 ]; then
        echo -n "$pkg,"
    fi
done

echo "" # Final newline
