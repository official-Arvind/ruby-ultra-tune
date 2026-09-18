#!/system/bin/sh
# ==============================================================================
# Ruby Ultra Tune v3.0 — App List Helper
# Author: Arvind Ji
# Authoritative package enumeration via Android's internal packages.list
# ==============================================================================

if [ -f /data/system/packages.list ]; then
    awk '{print $1}' /data/system/packages.list 2>/dev/null | sort -u | tr '\n' ','
elif [ -d /data/data ]; then
    ls -1 /data/data 2>/dev/null | grep '\.' | sort -u | tr '\n' ','
else
    pm list packages 2>/dev/null | cut -d: -f2 | sort -u | tr '\n' ','
fi
