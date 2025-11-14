#!/bin/ash

DATE=$(date "+%r  %A %d/%m/%Y")
HOSTNAME=$(uci get system.@system[0].hostname 2>/dev/null || echo "OpenWRT Router")

cat <<EOF | msmtp -a default ratulopenwrt@gmail.com
Subject: 📡 MWAN3 Updated — $HOSTNAME

Hello,

MWAN3 settings on **$HOSTNAME** have been updated.

🕒 Time: $DATE

Regards,  
OpenWRT System Reporter
EOF
./cpu_load_uptime.sh
exit 0
