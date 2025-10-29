#!/bin/bash

##
## Log-Rotation functions
##

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/util.sh"

log_message() {
    local level="$1"
    local message="$2"
    local log_file="$3"
    local timestamp=$(get_timestamp)
    write_to_file "[$timestamp] [$level] $message" "$log_file"
}

log_info() {
    log_message "[INFO]" "$1" "$2"
}

log_warning() {
    log_message "[WARNING]" "$1" "$2"
}

log_error() {
    log_message "[ERROR]" "$1" "$2"
}

validate_user_is_allowed() {
    local current_user="$1"
    local allowed_user="$2"
    [[ "$current_user" == "$allowed_user" ]]
}

validate_user_is_delegated() {
    local current_user="$1"
    local delegated_user="$2"
    [[ -n "$delegated_user" ]] && [[ "$current_user" == "$delegated_user" ]]
}

is_user_authorized() {
    local current_user="$1"
    local allowed_user="$2"
    local delegated_user="$3"
    
    validate_user_is_allowed "$current_user" "$allowed_user" || validate_user_is_delegated "$current_user" "$delegated_user"
}

zip_log_file() {
    local log_file="$1"
    local zip_file="$2"
    zip -jq "$zip_file" "$log_file"
}

remove_file() {
    local file_path="$1"
    rm -f "$file_path"
}

process_single_log_file() {
    local log_file="$1"
    local log_dir="$2"
    local status_log="$3"
    
    local filename=$(basename "$log_file")
    local date_str=$(get_date_string)
    local zip_file="$log_dir/${filename%.log}-$date_str.zip"
    
    zip_log_file "$log_file" "$zip_file"
    remove_file "$log_file"
    log_info "Zipped and removed: $filename -> $(basename $zip_file)" "$status_log"
}

get_old_zip_files() {
    local log_dir="$1"
    local days="$2"
    find "$log_dir" -name "*.zip" -type f -mtime "+$days"
}

delete_single_old_zip() {
    local zip_file="$1"
    local status_log="$2"
    
    remove_file "$zip_file"
    log_info "Deleted old zip: $(basename $zip_file)" "$status_log"
}

calculate_zip_statistics() {
    local log_dir="$1"
    local status_log="$2"
    
    local zip_count=$(count_files_in_directory "$log_dir" "*.zip")
    local largest_zip=$(find_largest_file "$log_dir" "*.zip")
    
    log_info "Total zip files: $zip_count" "$status_log"
    
    if [[ -n "$largest_zip" ]] && file_exists "$largest_zip"; then
        local size=$(get_file_size "$largest_zip")
        local size_mb=$(bytes_to_mb "$size")
        local mod_time=$(get_file_modification_time "$largest_zip")
        log_info "Largest zip: $(basename $largest_zip) - Size: ${size_mb}MB - Created: $mod_time" "$status_log"
    fi
}

check_directory_size_threshold() {
    local log_dir="$1"
    local threshold_mb="$2"
    
    local dir_size=$(get_directory_size "$log_dir")
    local dir_size_mb=$(bytes_to_mb "$dir_size")
    local threshold_bytes=$((threshold_mb * 1048576))
    
    [[ $dir_size -ge $threshold_bytes ]]
}

log_size_warning() {
    local log_dir="$1"
    local threshold_mb="$2"
    local status_log="$3"
    
    local dir_size=$(get_directory_size "$log_dir")
    local dir_size_mb=$(bytes_to_mb "$dir_size")
    log_warning "Directory size (${dir_size_mb}MB) exceeds threshold (${threshold_mb}MB)" "$status_log"
}

ensure_directory_exists() {
    local dir_path="$1"
    if ! directory_exists "$dir_path"; then
        create_directory "$dir_path"
    fi
}

ensure_log_file_exists() {
    local log_file="$1"
    if ! file_exists "$log_file"; then
        touch "$log_file"
    fi
}

get_all_log_files() {
    local log_dir="$1"
    find "$log_dir" -maxdepth 1 -name "*.log" -type f
}
