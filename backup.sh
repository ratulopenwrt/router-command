#!/bin/ash

# === Variables ===
DATE=$(date "+%Y%m%d_%H%M%S")
BACKUP_FILE="/tmp/HX21_auto_backup_$DATE.tar.gz"
EMAIL="ratulopenwrt@gmail.com"

# === Create backup ===
sysupgrade -b "$BACKUP_FILE"

# === Send email with backup attached ===
cat <<EOF | mutt -s "💾 HX21 Router Backup - $DATE" -a "$BACKUP_FILE" -- "$EMAIL"
Hello!

Your IMOU HX21 Router has been successfully backed up automatically by OpenWRT.  

You can keep this backup for safe-keeping or restore it if needed.

-------------
| IMOU HX21 |
-------------

Backup Time: $(date "+%r  %A %d/%m/%Y")

Stay safe and enjoy your internet!  
— OpenWRT
EOF

# === Cleanup ===
rm -f "$BACKUP_FILE" sent 2>/dev/null

exit 0
