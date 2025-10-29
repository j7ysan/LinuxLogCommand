#!/bin/bash

##
## CIS-341 Log Rotation System - Main Script
##

set -o pipefail 

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/util.sh"
source "$SCRIPT_DIR/functions.sh"

# Default configuration
DEFAULT_CONFIG="/course_project/log.cfg"
CONFIG_FILE="$DEFAULT_CONFIG"
LOG_DIR="/course_project/log"
OWN_LOG="/var/log/logrotate_status.log"
LOGMANAGER_USER="logmanager"
DELEGATED_USER=""
SIZE_WARNING_THRESHOLD_MB=100
ZIP_RETENTION_DAYS=14

show_usage() {
    cat << EOF
USAGE: $(basename "$0") [OPTIONS]

CIS-341 Log Rotation System
Automatically rotates log files, creates zip archives, and manages old archives.

OPTIONS:
    -c, --config FILE      Configuration file path (default: $DEFAULT_CONFIG)
    -d, --dir DIR          Log directory to process (default: $LOG_DIR)
    -l, --log FILE         Status log file path (default: $OWN_LOG)
    -u, --user USER        Allowed user (default: $LOGMANAGER_USER)
    -t, --threshold MB     Size warning threshold in MB (default: $SIZE_WARNING_THRESHOLD_MB)
    -r, --retention DAYS   Zip retention period in days (default: $ZIP_RETENTION_DAYS)
    -D, --delegate USER    Delegated user who can also run this script
    -h, --help             Show this help message

CONFIGURATION FILE (log.cfg):
    LOG_DIR="/course_project/log"
    OWN_LOG="/var/log/logrotate_status.log"
    LOGMANAGER_USER="logmanager"
    DELEGATED_USER=""
    SIZE_WARNING_THRESHOLD_MB=100
    ZIP_RETENTION_DAYS=14

EXAMPLES:
    # Run with default configuration
    sudo -u logmanager $(basename "$0")

    # Run with custom config file
    sudo -u logmanager $(basename "$0") --config /etc/mylog.cfg

    # Override log directory and threshold
    sudo -u logmanager $(basename "$0") --dir /var/myapp/logs --threshold 200

    # Delegate to another user
    sudo -u logmanager $(basename "$0") --delegate appuser
    sudo -u appuser $(basename "$0")

BEHAVIOR:
    1. Validates user authorization (must be LOGMANAGER_USER or DELEGATED_USER)
    2. Zips all *.log files in LOG_DIR and removes originals
    3. Deletes zip files older than ZIP_RETENTION_DAYS (default: 14 days)
    4. Logs statistics: total zips, largest zip with size and timestamp
    5. Warns if LOG_DIR size exceeds SIZE_WARNING_THRESHOLD_MB

EXIT CODES:
    0   Success
    1   Unauthorized user
    2   Configuration file not found
    3   Log directory does not exist
    4   Failed to create required directories/files
    5   General error during execution

NOTES:
    - Command-line parameters override configuration file settings
    - Script must be run by LOGMANAGER_USER or DELEGATED_USER
    - Creates LOG_DIR and OWN_LOG if they don't exist
    - All operations are logged to OWN_LOG with timestamps

EOF
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -d|--dir)
                CLI_LOG_DIR="$2"
                shift 2
                ;;
            -l|--log)
                CLI_OWN_LOG="$2"
                shift 2
                ;;
            -u|--user)
                CLI_LOGMANAGER_USER="$2"
                shift 2
                ;;
            -t|--threshold)
                CLI_SIZE_WARNING_THRESHOLD_MB="$2"
                shift 2
                ;;
            -r|--retention)
                CLI_ZIP_RETENTION_DAYS="$2"
                shift 2
                ;;
            -D|--delegate)
                CLI_DELEGATED_USER="$2"
                shift 2
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                echo "Error: Unknown option: $1" >&2
                show_usage
                exit 5
                ;;
        esac
    done
}

apply_cli_overrides() {
    [[ -n "$CLI_LOG_DIR" ]] && LOG_DIR="$CLI_LOG_DIR"
    [[ -n "$CLI_OWN_LOG" ]] && OWN_LOG="$CLI_OWN_LOG"
    [[ -n "$CLI_LOGMANAGER_USER" ]] && LOGMANAGER_USER="$CLI_LOGMANAGER_USER"
    [[ -n "$CLI_SIZE_WARNING_THRESHOLD_MB" ]] && SIZE_WARNING_THRESHOLD_MB="$CLI_SIZE_WARNING_THRESHOLD_MB"
    [[ -n "$CLI_ZIP_RETENTION_DAYS" ]] && ZIP_RETENTION_DAYS="$CLI_ZIP_RETENTION_DAYS"
    [[ -n "$CLI_DELEGATED_USER" ]] && DELEGATED_USER="$CLI_DELEGATED_USER"
}

load_configuration() {
    if file_exists "$CONFIG_FILE"; then
        read_config_file "$CONFIG_FILE"
    else
        if [[ "$CONFIG_FILE" != "$DEFAULT_CONFIG" ]]; then
            echo "Error: Configuration file not found: $CONFIG_FILE" >&2
            exit 2
        fi
    fi
}

validate_authorization() {
    local current_user=$(get_current_user)
    
    if ! is_user_authorized "$current_user" "$LOGMANAGER_USER" "$DELEGATED_USER"; then
        echo "Error: Unauthorized user '$current_user'. Only '$LOGMANAGER_USER'${DELEGATED_USER:+ or '$DELEGATED_USER'} can run this script." >&2
        exit 1
    fi
}

initialize_environment() {
    ensure_directory_exists "$LOG_DIR" || {
        echo "Error: Cannot create log directory: $LOG_DIR" >&2
        exit 4
    }
    
    local log_dir_parent=$(dirname "$OWN_LOG")
    ensure_directory_exists "$log_dir_parent" || {
        echo "Error: Cannot create log file directory: $log_dir_parent" >&2
        exit 4
    }
    
    ensure_log_file_exists "$OWN_LOG" || {
        echo "Error: Cannot create status log file: $OWN_LOG" >&2
        exit 4
    }
}

process_log_files() {
    local log_files=$(get_all_log_files "$LOG_DIR")
    local count=0
    
    if [[ -z "$log_files" ]]; then
        log_info "No log files found to process" "$OWN_LOG"
        return 0
    fi
    
    while IFS= read -r log_file; do
        if file_exists "$log_file"; then
            process_single_log_file "$log_file" "$LOG_DIR" "$OWN_LOG"
            ((count++))
        fi
    done <<< "$log_files"
    
    log_info "Processed $count log file(s)" "$OWN_LOG"
}

cleanup_old_zips() {
    local old_zips=$(get_old_zip_files "$LOG_DIR" "$ZIP_RETENTION_DAYS")
    local count=0
    
    if [[ -z "$old_zips" ]]; then
        log_info "No old zip files to delete" "$OWN_LOG"
        return 0
    fi
    
    while IFS= read -r zip_file; do
        if file_exists "$zip_file"; then
            delete_single_old_zip "$zip_file" "$OWN_LOG"
            ((count++))
        fi
    done <<< "$old_zips"
    
    log_info "Deleted $count old zip file(s)" "$OWN_LOG"
}

check_and_log_statistics() {
    calculate_zip_statistics "$LOG_DIR" "$OWN_LOG"
}

check_size_warning() {
    if check_directory_size_threshold "$LOG_DIR" "$SIZE_WARNING_THRESHOLD_MB"; then
        log_size_warning "$LOG_DIR" "$SIZE_WARNING_THRESHOLD_MB" "$OWN_LOG"
    fi
}

main() {
    parse_arguments "$@"
    load_configuration
    apply_cli_overrides
    validate_authorization
    initialize_environment
    
    log_info "=== Log rotation started by $(get_current_user) ===" "$OWN_LOG"
    
    if ! directory_exists "$LOG_DIR"; then
        log_error "Log directory does not exist: $LOG_DIR" "$OWN_LOG"
        exit 3
    fi
    
    process_log_files
    cleanup_old_zips
    check_and_log_statistics
    check_size_warning
    
    log_info "=== Log rotation completed successfully ===" "$OWN_LOG"
    exit 0
}

main "$@"
