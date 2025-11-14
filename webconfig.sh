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
firewall:/etc/config/firewall:firewall:::./upf.sh
root:/etc/crontabs/root:cron::
sysupgrade.conf:/etc/sysupgrade.conf:::
rc.local:/etc/rc.local:::

# === Scripts in /root ===
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

# === NEW: mwan3 configuration ===
mwan3:/etc/config/mwan3:mwan3::::./mw3u.sh
"

# Function to update file if changed
update_file() {
    src="$1"
    dest="$2"
    service="$3"
    pre="$4"
    post="$5"

    # sanity checks
    [ -z "$src" ] && log "Empty source; skipping." && return
    [ -z "$dest" ] && log "Empty destination for $src; skipping." && rm -f "$TMP_DIR/$src" 2>/dev/null && return

    # run pre (if executable)
    if [ -n "$pre" ] && [ -x "$pre" ]; then
        log "Running pre-script $pre for $dest"
        "$pre" >> "$LOG_FILE" 2>&1
    fi

    # ensure dest dir exists
    destdir=$(dirname "$dest")
    if [ -n "$destdir" ]; then
        mkdir -p "$destdir" 2>/dev/null || true
    fi

    # move downloaded file into place
    if mv "$TMP_DIR/$src" "$dest" 2>/dev/null; then
        log "Updated $dest"
    else
        log "Failed to move $TMP_DIR/$src -> $dest"
        rm -f "$TMP_DIR/$src" 2>/dev/null
        return
    fi

    # restart service if provided
    if [ -n "$service" ]; then
        if service "$service" restart >> "$LOG_FILE" 2>&1; then
            log "Restarted service $service"
        else
            log "Failed to restart service $service"
        fi
    fi

    # run post (if executable). try from /root too for ./script cases
    if [ -n "$post" ]; then
        # if post is executable as given, run it
        if [ -x "$post" ]; then
            log "Executing post-script $post"
            (cd /root 2>/dev/null; "$post") >> "$LOG_FILE" 2>&1 &
            log "Launched post-script $post (background)"
        elif [ -x "/root/$post" ]; then
            log "Executing post-script /root/$post"
            (cd /root 2>/dev/null; "/root/$post") >> "$LOG_FILE" 2>&1 &
            log "Launched /root/$post (background)"
        else
            # try to execute by basename in /root (covers ./upwc.sh and bare names)
            bn=$(basename "$post")
            if [ -x "/root/$bn" ]; then
                log "Executing post-script /root/$bn"
                (cd /root 2>/dev/null; "/root/$bn") >> "$LOG_FILE" 2>&1 &
                log "Launched /root/$bn (background)"
            else
                log "Post-script $post not executable or not found; skipping"
            fi
        fi
    fi
}

# === Download and process files ===
# Use a safe line-by-line reader so blank lines and comments are ignored.
printf '%s\n' "$FILES" | while IFS= read -r line; do
    # trim leading/trailing whitespace (simple)
    # (busybox ash doesn't have fancy parameter expansions portably; assume no weird whitespace)
    case "$line" in
        ''|\#*) continue ;;   # skip empty lines and comments
    esac

    # parse the 5 colon-separated fields
    OLDIFS=$IFS
    IFS=':'
    set -- $line
    IFS=$OLDIFS

    FILE_SRC=${1:-}
    FILE_DEST=${2:-}
    FILE_SERVICE=${3:-}
    FILE_PRE=${4:-}
    FILE_POST=${5:-}

    # skip if no source
    [ -z "$FILE_SRC" ] && continue

    # download to tmp
    wget -q -O "$TMP_DIR/$FILE_SRC" "$REMOTE_BASE/$FILE_SRC"
    if [ ! -s "$TMP_DIR/$FILE_SRC" ]; then
        log "Download failed or empty for $FILE_SRC"
        rm -f "$TMP_DIR/$FILE_SRC" 2>/dev/null
        continue
    fi

    # if dest exists and identical, remove tmp and skip
    if [ -n "$FILE_DEST" ] && [ -f "$FILE_DEST" ]; then
        if cmp -s "$TMP_DIR/$FILE_SRC" "$FILE_DEST"; then
            log "No change for $FILE_DEST; skipping"
            rm -f "$TMP_DIR/$FILE_SRC" 2>/dev/null
            continue
        fi
    fi

    update_file "$FILE_SRC" "$FILE_DEST" "$FILE_SERVICE" "$FILE_PRE" "$FILE_POST"
done

# Make all /root scripts executable
chmod +x /root/*.sh 2>/dev/null || true

log "Update run completed."
exit 0
