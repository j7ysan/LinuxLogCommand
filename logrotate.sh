#!/bin/bash


# Default configuration 
CONFIG_FILE="log.cfg"
LOG_DIR="courseprojectlog"
OWN_LOG="logrotate_status.log"
WARNING_SIZE_MB=100


if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi


# TASK 9: Override from command line

if [ -n "$1" ]; then
    LOG_DIR="$1"
fi
if [ -n "$2" ]; then
    WARNING_SIZE_MB="$2"
fi

THRESHOLD=$((WARNING_SIZE_MB * 1024))

echo "Using LOG_DIR=$LOG_DIR and THRESHOLD=$THRESHOLD KB"


mkdir -p "$LOG_DIR"
if [ ! -d "$LOG_DIR" ]; then
    echo "ERROR: Could not create directory $LOG_DIR"
    exit 1
fi
touch "$OWN_LOG"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$OWN_LOG"
}


# TASK 7: total and largest zip files

total=$(ls "$LOG_DIR"/*.zip 2>/dev/null | wc -l)
largest=$(ls -S "$LOG_DIR"/*.zip 2>/dev/null | head -n 1)

if [ -n "$largest" ]; then
    size=$(du -h "$largest" | cut -f1)
    timestamp=$(stat -c %y "$largest" | cut -d'.' -f1)
    log "Total zipped files: $total, Largest: $(basename "$largest") ($size, created $timestamp)"
else
    log "No zipped files found in $LOG_DIR"
fi


# TASK 8: folder size warning

current_size=$(du -sk "$LOG_DIR" | cut -f1)

if [ "$current_size" -gt "$THRESHOLD" ]; then
    log "WARNING - Log folder exceeded ${THRESHOLD}KB (Current size: ${current_size}KB)"
else
    log "Folder size is within limit (${current_size}KB)"
fi

echo "Script finished. Check $OWN_LOG for results."
