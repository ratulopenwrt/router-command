#!/bin/ash

DATE=$(date "+%r  %A %d/%m/%Y")
HOSTNAME=$(uci get system.@system[0].hostname 2>/dev/null || echo "OpenWRT Router")

cat <<EOF | msmtp -a default ratulopenwrt@gmail.com
Subject: 🛠 Web Config Updated — $HOSTNAME

Hello,

Web configuration on **$HOSTNAME** has been updated.

🕒 Time: $DATE

Regards,  
OpenWRT System Reporter
EOF

exit 0
