#!/bin/ash

# === Configuration ===
TMP_DIR="/tmp"
REMOTE_BASE="https://raw.githubusercontent.com/ratulopenwrt/router-command/main"
LOG_FILE="/tmp/update_router.log"

NOW=$(date "+%Y-%m-%d %H:%M:%S")

# Files to manage: src:dest:service:pre_script:post_script
# '' for empty fields
FILES="
aliases:/etc/aliases:::
ethers:/etc/ethers:::
firewall:/etc/config/firewall:firewall:./upf.sh:
wireless:/etc/config/wireless:network:./upw.sh:
root:/etc/crontabs/root:cron::
sysupgrade.conf:/etc/sysupgrade.conf:::
rc.local:/etc/rc.local:::

backup.sh:/root/backup.sh:::
cpu_load_uptime.sh:/root/cpu_load_uptime.sh::./cpu_load_uptime.sh:
pay_bill_notice.sh:/root/pay_bill_notice.sh:::
reboot_message.sh:/root/reboot_message.sh::./reboot_message.sh:
upf.sh:/root/upf.sh:::
upw.sh:/root/upw.sh:::
upwc.sh:/root/upwc.sh:::
webcommand.sh:/root/webcommand.sh::./root/webcommand.sh:
webconfig.sh:/root/webconfig.sh::./upwc.sh:
"

# Function to update file if changed
update_file() {
    src="$1"
    dest="$2"
    service="$3"
    pre="$4"
    post="$5"

    if [ ! -f "$src" ]; then
        echo "[$NOW] File $src not found, skipping." >> "$LOG_FILE"
        return
    fi

    if [ ! -f "$dest" ] || ! cmp -s "$src" "$dest"; then
        [ -n "$pre" ] && [ -x "$pre" ] && "$pre" >> "$LOG_FILE" 2>&1
        mv "$src" "$dest"
        echo "[$NOW] Updated $dest" >> "$LOG_FILE"
        [ -n "$service" ] && service "$service" restart && echo "[$NOW] Restarted service $service" >> "$LOG_FILE"
        [ -n "$post" ] && [ -x "$post" ] && "$post" & echo "[$NOW] Executed post script $post" >> "$LOG_FILE"
    else
        rm -f "$src"
    fi
}

# Download and process files
for line in $FILES; do
    set -- $(echo "$line" | tr ':' ' ')
    FILE_SRC="$1"
    FILE_DEST="$2"
    FILE_SERVICE="$3"
    FILE_PRE="$4"
    FILE_POST="$5"

    # Download file from GitHub
    wget -q -O "$TMP_DIR/$FILE_SRC" "$REMOTE_BASE/$FILE_SRC"

    # Update if downloaded
    [ -f "$TMP_DIR/$FILE_SRC" ] && update_file "$TMP_DIR/$FILE_SRC" "$FILE_DEST" "$FILE_SERVICE" "$FILE_PRE" "$FILE_POST"
done

# === Give executable permission to all .sh scripts in /root ===
chmod +x /root/*.sh 2>/dev/null

echo "[$NOW] Update run completed." >> "$LOG_FILE"

exit 0
