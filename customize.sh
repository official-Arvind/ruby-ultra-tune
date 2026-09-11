SKIPUNZIP=0

ui_print "***************************************************"
ui_print "* Ruby Ultra Performance & Hotspot Thermal Nuker *"
ui_print "* Author: Arvind Ji                               *"
ui_print "* Target: Redmi Note 12 Pro 5G (ruby / MT6877)    *"
ui_print "***************************************************"

set_perm_recursive $MODPATH 0 0 0755 0644
set_perm $MODPATH/service.sh 0 0 0755
