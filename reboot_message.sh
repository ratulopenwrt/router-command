#!/bin/ash

# === Basic Info ===
DATE=$(date "+%r  %A %d/%m/%Y")
HOSTNAME=$(uci get system.@system[0].hostname 2>/dev/null || echo "OpenWRT Router")
UPTIME_BEFORE=$(awk '{printf "%.2f minutes", $1/60}' /proc/uptime)
IPV4_ADDR=$(ip addr show | awk '/inet / {print $2}' | cut -d/ -f1 | head -n1)
WAN_IP=$(wget -qO- http://ifconfig.me/ip 2>/dev/null || echo "N/A")

# === Build Message ===
cat <<EOF | msmtp -a default ratulopenwrt@gmail.com
Subject: 🔄 $HOSTNAME has rebooted — $DATE

Hello,

This is an automatic notification to inform you that **$HOSTNAME** has successfully **rebooted**.

────────────────────────────
🕒 **Reboot Time:** $DATE  
⏱ **Previous Uptime:** $UPTIME_BEFORE  
🌐 **Local IP:** $IPV4_ADDR  
🌍 **Public IP:** $WAN_IP  
────────────────────────────

✅ System has started successfully and all core services are now running.

If this reboot was **unexpected**, please review your system logs or uptime policy.

Best regards,  
**OpenWRT**
EOF

exit 0
