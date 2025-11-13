#!/bin/ash

# === Configuration ===
TMP_DIR="/tmp"
REMOTE_BASE="https://raw.githubusercontent.com/ratulopenwrt/router-command/main"
LOCK_FILE="/tmp/update_router.lock"
LOG_FILE="/tmp/update_router.log"

# Timestamp for this run
NOW=$(date "+%Y-%m-%d %H:%M:%S")

# Exit if another instance is running
if [ -f "$LOCK_FILE" ]; then
    echo "[$NOW] Another instance is running. Exiting." >> "$LOG_FILE"
    exit 0
fi
touch "$LOCK_FILE"

# Files to manage: src_filename:dest_path:service:pre_script:post_script
FILES="
ethers:/etc/ethers:::
firewall:/etc/config/firewall:firewall:./upf.sh:
wireless:/etc/config/wireless:network:./upw.sh:
root:/etc/crontabs/root:cron::
sysupgrade.conf:/etc/sysupgrade.conf:::
webcommand.sh:/root/webcommand.sh:::""sh /root/webcommand.sh"
webconfig.sh:/root/webconfig.sh:::./upwc.sh:
"

# Function to update file if changed
update_file() {
    local src="$1"
    local dest="$2"
    local service="$3"
    local pre_script="$4"
    local post_script="$5"
    local changed=0

    if [ ! -f "$src" ]; then
        echo "[$NOW] File $src not found, skipping." >> "$LOG_FILE"
        return
    fi

    if [ ! -f "$dest" ] || ! cmp -s "$src" "$dest"; then
        [ -n "$pre_script" ] && [ -x "$pre_script" ] && "$pre_script" >> "$LOG_FILE" 2>&1
        mv "$src" "$dest"
        echo "[$NOW] Updated $dest" >> "$LOG_FILE"
        [ -n "$service" ] && service "$service" restart && echo "[$NOW] Restarted service $service" >> "$LOG_FILE"
        [ -n "$post_script" ] && [ -x "$post_script" ] && "$post_script" & echo "[$NOW] Executed post script $post_script" >> "$LOG_FILE"
        changed=1
    else
        rm -f "$src"
    fi
    return $changed
}

# Download and process files
for line in $FILES; do
    IFS=":" read src dest service pre post <<EOF
$line
EOF

    # Download only if changed on server
    wget -q -N -P "$TMP_DIR" "$REMOTE_BASE/$src"

    [ -f "$TMP_DIR/$src" ] && update_file "$TMP_DIR/$src" "$dest" "$service" "$pre" "$post"
done

# Cleanup lock
rm -f "$LOCK_FILE"
echo "[$NOW] Update run completed." >> "$LOG_FILE"

exit 0
