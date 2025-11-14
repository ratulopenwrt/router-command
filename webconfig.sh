#!/bin/ash

# Simple, busybox/ash-compatible updater
# Downloads files from REMOTE_BASE and moves them to DEST,
# optionally restarting a service and running pre/post scripts.

TMP_DIR="/tmp"
REMOTE_BASE="https://raw.githubusercontent.com/ratulopenwrt/router-command/main"
LOG_FILE="/tmp/update_router.log"

log() {
    NOW=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$NOW] $1" >> "$LOG_FILE"
}

# Files to manage: src:dest:service:pre_script:post_script
FILES="
aliases:/etc/aliases:::
ethers:/etc/ethers:::
firewall:/etc/config/firewall::::./upf.sh
root:/etc/crontabs/root:cron::
sysupgrade.conf:/etc/sysupgrade.conf:::
rc.local:/etc/rc.local:::

backup.sh:/root/backup.sh:::
cpu_load_uptime.sh:/root/cpu_load_uptime.sh::::./cpu_load_uptime.sh
pay_bill_notice.sh:/root/pay_bill_notice.sh:::
reboot_message.sh:/root/reboot_message.sh::::./reboot_message.sh
upf.sh:/root/upf.sh:::
upw.sh:/root/upw.sh:::
upwc.sh:/root/upwc.sh:::
mw3u.sh:/root/mw3u.sh:::
webcommand.sh:/root/webcommand.sh::::./webcommand.sh
webconfig.sh:/root/webconfig.sh::::./upwc.sh
mwan3:/etc/config/mwan3:mwan3::::./mw3u.sh
"

# Ensure all /root scripts are executable before running
chmod +x /root/*.sh 2>/dev/null || true

# Helper to run post-scripts reliably
run_post() {
    post="$1"
    [ -z "$post" ] && return
    for p in "$post" "/root/$post" "/root/$(basename "$post")"; do
        if [ -x "$p" ]; then
            log "Running post-script $p"
            "$p" >> "$LOG_FILE" 2>&1 &
            log "Launched $p (background)"
            return
        fi
    done
    log "Post-script $post not found or not executable"
}

# Function to update a single file
update_file() {
    src="$1"
    dest="$2"
    service="$3"
    pre="$4"
    post="$5"

    [ -z "$src" ] && log "Empty source; skipping." && return
    [ -z "$dest" ] && log "Empty destination for $src; skipping." && rm -f "$TMP_DIR/$src" 2>/dev/null && return

    # Run pre-script if executable
    [ -n "$pre" ] && [ -x "$pre" ] && log "Running pre-script $pre for $dest" && "$pre" >> "$LOG_FILE" 2>&1

    # Ensure destination directory exists
    destdir=$(dirname "$dest")
    [ -n "$destdir" ] && mkdir -p "$destdir" 2>/dev/null || true

    # Move downloaded file into place
    if mv "$TMP_DIR/$src" "$dest" 2>/dev/null; then
        log "Updated $dest"
    else
        log "Failed to move $TMP_DIR/$src -> $dest"
        rm -f "$TMP_DIR/$src" 2>/dev/null
        return
    fi

    # Restart service if specified
    [ -n "$service" ] && service "$service" restart >> "$LOG_FILE" 2>&1 && log "Restarted service $service"

    # Run post-script
    run_post "$post"
}

# === Download and process files ===
while IFS= read -r line; do
    # Skip empty lines and comments
    case "$line" in
        ''|\#*) continue ;;
    esac

    # Parse colon-separated fields
    OLDIFS=$IFS
    IFS=':'
    set -- $line
    IFS=$OLDIFS

    FILE_SRC=${1:-}
    FILE_DEST=${2:-}
    FILE_SERVICE=${3:-}
    FILE_PRE=${4:-}
    FILE_POST=${5:-}

    [ -z "$FILE_SRC" ] && continue

    # Download to tmp
    wget -q -O "$TMP_DIR/$FILE_SRC" "$REMOTE_BASE/$FILE_SRC"
    if [ ! -s "$TMP_DIR/$FILE_SRC" ]; then
        log "Download failed or empty for $FILE_SRC"
        rm -f "$TMP_DIR/$FILE_SRC" 2>/dev/null
        continue
    fi

    # Skip if destination exists and is identical
    if [ -n "$FILE_DEST" ] && [ -f "$FILE_DEST" ]; then
        cmp -s "$TMP_DIR/$FILE_SRC" "$FILE_DEST" && log "No change for $FILE_DEST; skipping" && rm -f "$TMP_DIR/$FILE_SRC" 2>/dev/null && continue
    fi

    update_file "$FILE_SRC" "$FILE_DEST" "$FILE_SERVICE" "$FILE_PRE" "$FILE_POST"
done <<EOF
$FILES
EOF

log "Update run completed."
exit 0
