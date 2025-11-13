#!/bin/ash

# === System Information ===
DATE=$(date "+%r  %A %d/%m/%Y")
HOSTNAME=$(uci get system.@system[0].hostname 2>/dev/null || echo "OpenWRT Router")
UPTIME=$(uptime | awk -F'( |,|:)+' '{print $6" hours, "$7" minutes"}')
LOAD_AVG=$(awk '{print "1min: "$1", 5min: "$2", 15min: "$3}' /proc/loadavg)
CPU_TEMP=$(awk '{sum+=$1} END {if(NR>0) printf "%.1f°C\n", sum/NR/1000; else print "N/A"}' /sys/class/thermal/thermal_zone*/temp 2>/dev/null)

# === Network Information ===
IPV4_ADDR=$(ip addr show | awk '/inet / {print $2}' | cut -d/ -f1)
WAN_IP=$(wget -qO- http://ifconfig.me/ip 2>/dev/null || echo "N/A")
SSID=$(iwinfo | awk -F'"' '/ESSID/ {print $2; exit}')

# === Memory Usage ===
MEM_TOTAL=$(awk '/MemTotal/ {printf "%.1f MB", $2/1024}' /proc/meminfo)
MEM_FREE=$(awk '/MemAvailable/ {printf "%.1f MB", $2/1024}' /proc/meminfo)
MEM_USED=$(awk -v t=$(awk '/MemTotal/ {print $2}' /proc/meminfo) -v f=$(awk '/MemAvailable/ {print $2}' /proc/meminfo) 'BEGIN {printf "%.1f MB", (t-f)/1024}')

# === Storage Info ===
STORAGE=$(df -h | awk 'NR==1 || /overlay/')

# === Connected Devices (LAN) with hostnames ===
LAN_DEVICES=""
for line in $(ip neigh show | awk '{print $1" "$5}'); do
    IP=$(echo $line | cut -d' ' -f1)
    MAC=$(echo $line | cut -d' ' -f2 | tr '[:upper:]' '[:lower:]')

    # Try DHCP leases first
    HOSTNAME=$(awk -v mac="$MAC" 'BEGIN{h="*"} $2==mac {if($4!="*") h=$4; print h; exit}' /tmp/dhcp.leases)
    
    # If DHCP lease has no hostname, fallback to /etc/ethers
    if [ "$HOSTNAME" = "*" ]; then
        HOSTNAME=$(awk -v mac="$MAC" 'tolower($1)==mac {print $2; exit}' /etc/ethers)
    fi

    # Default to unknown if still empty
    [ -z "$HOSTNAME" ] && HOSTNAME="unknown"

    # Append with a real newline
    LAN_DEVICES="$LAN_DEVICES$IP -> $MAC ($HOSTNAME)
"
done



# === Connected Wi-Fi Clients with signal strength ===
WIFI_DEVICES=$(iwinfo | awk -F': ' '
/Interface/ {iface=$2}
/ESSID/ {ssid=$2}
/Associated MAC/ {
    mac=$2
    getline
    getline
    sig=""
    while($0 ~ /Signal/) {
        sig=$2
        getline
    }
    print mac " (" ssid ", signal: " sig ")"
}')

# === Build the Message ===
cat <<EOF | msmtp -a default ratulopenwrt@gmail.com
Subject: 📊 $HOSTNAME Status Report — $DATE

Hello,

Here’s your latest **router health report** from $HOSTNAME.

────────────────────────────
📅 Time: $DATE
────────────────────────────

🖥 **System Info**
Hostname: $HOSTNAME
Uptime: $UPTIME
CPU Load: $LOAD_AVG
CPU Temp: $CPU_TEMP

────────────────────────────
🌐 **Network Info**
Local IP(s): 
$IPV4_ADDR
WAN IP: $WAN_IP
SSID: ${SSID:-N/A}

────────────────────────────
💾 **Memory Usage**
Total: $MEM_TOTAL
Used: $MEM_USED
Free: $MEM_FREE

────────────────────────────
🗄 **Storage**
$STORAGE

────────────────────────────
📱 **Connected Devices (LAN)**
$LAN_DEVICES

📶 **Connected Devices (Wi-Fi)**
$WIFI_DEVICES

────────────────────────────
Report generated automatically by OpenWRT.

Best regards,  
OpenWRT System Reporter
EOF

exit 0
