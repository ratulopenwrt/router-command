#!/bin/ash

DATE=$(date "+%r  %A %d/%m/%Y")
HOSTNAME=$(uci get system.@system[0].hostname 2>/dev/null || echo "OpenWRT Router")

cat <<EOF | msmtp -a default ratulopenwrt@gmail.com
Subject: 🔐 Firewall Updated — $HOSTNAME

Hello,

The firewall configuration on **$HOSTNAME** has been successfully updated.

🕒 Time: $DATE

Regards,  
OpenWRT System Reporter
EOF

service firewall restart

exit 0
