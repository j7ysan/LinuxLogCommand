#!/bin/bash
# CIS-341 Log Rotation System - Parts 4, 5, 6

# Part 4: Read config file values
CONFIG_FILE="log.cfg"
LOG_DIR="courseprojectlog"
OWN_LOG="logrotate_status.log"
ZIP_USER="logmanager"

if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
fi

mkdir -p "$LOG_DIR"
touch "$OWN_LOG"

# Part 5: Write status log entries
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$OWN_LOG"
}
log "Script started by $(whoami)"

# Example log zipping (simplified—expand for your full app)
for f in "$LOG_DIR"/*.log; do
  if [[ -f "$f" ]]; then
    zip_file="${f}-$(date '+%Y%m%d').zip"
    zip -j "$zip_file" "$f"
    rm "$f"
    log "Zipped $f to $zip_file"
  fi
done

# Part 6: Delete zipped files
find "$LOG_DIR" -name "*.zip" -mtime +14 -exec rm {} \; -exec log "Deleted old zip {}" \;

log "Script finished"
exit 0
