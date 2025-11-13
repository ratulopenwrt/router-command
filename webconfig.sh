#!/bin/ash

# === Configuration ===
TMP_DIR="/tmp"
REMOTE_BASE="https://raw.githubusercontent.com/ratulopenwrt/router-command/main"
LOCK_FILE="/tmp/update_router.lock"
LOG_FILE="/tmp/update_router.log"

NOW=$(date "+%Y-%m-%d %H:%M:%S")

# Exit if another instance is running
if [ -f "$LOCK_FILE" ]; then
    echo "[$NOW] Another instance is running. Exiting." >> "$LOG_FILE"
    exit 0
fi
touch "$LOCK_FILE"

# Files to manage: src:dest:service:pre_script:post_script
# Use empty string '' for fields that are empty
FILES="
ethers:/etc/ethers:''':'' 
firewall:/etc/config/firewall:firewall:./upf.sh:'' 
wireless:/etc/config/wireless:network:./upw.sh:'' 
root:/etc/crontabs/root:cron:'' 
sysupgrade.conf:/etc/sysupgrade.conf:'':'' 
webcommand.sh:/root/webcommand.sh:'':'sh /root/webcommand.sh' 
webconfig.sh:/root/webconfig.sh:'':'./upwc.sh':'' 
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
        [ "$pre" != "''" ] && [ -x "$pre" ] && "$pre" >> "$LOG_FILE" 2>&1
        mv "$src" "$dest"
        echo "[$NOW] Updated $dest" >> "$LOG_FILE"
        [ "$service" != "''" ] && service "$service" restart && echo "[$NOW] Restarted service $service" >> "$LOG_FILE"
        [ "$post" != "''" ] && [ -x "$post" ] && "$post" & echo "[$NOW] Executed post script $post" >> "$LOG_FILE"
    else
        rm -f "$src"
    fi
}

# Download and process files
for line in $FILES; do
    # Split by colon
    set -- $(echo "$line" | tr ':' ' ')
    FILE_SRC="$1"
    FILE_DEST="$2"
    FILE_SERVICE="$3"
    FILE_PRE="$4"
    FILE_POST="$5"

    # Download
    wget -q -N -P "$TMP_DIR" "$REMOTE_BASE/$FILE_SRC"

    # Update if exists
    [ -f "$TMP_DIR/$FILE_SRC" ] && update_file "$TMP_DIR/$FILE_SRC" "$FILE_DEST" "$FILE_SERVICE" "$FILE_PRE" "$FILE_POST"
done

# Cleanup
rm -f "$LOCK_FILE"
echo "[$NOW] Update run completed." >> "$LOG_FILE"

exit 0
