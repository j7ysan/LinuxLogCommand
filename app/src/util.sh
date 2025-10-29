#!/bin/bash

##
## Utility Functions - Generic helpers
##

get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

get_date_string() {
    date '+%Y%m%d'
}

write_to_file() {
    local message="$1"
    local file_path="$2"
    echo "$message" >> "$file_path"
}

file_exists() {
    local file_path="$1"
    [[ -f "$file_path" ]]
}

directory_exists() {
    local dir_path="$1"
    [[ -d "$dir_path" ]]
}

create_directory() {
    local dir_path="$1"
    mkdir -p "$dir_path"
}

get_file_size() {
    local file_path="$1"
    stat -f%z "$file_path" 2>/dev/null || stat -c%s "$file_path" 2>/dev/null
}

get_directory_size() {
    local dir_path="$1"
    du -sb "$dir_path" 2>/dev/null | awk '{print $1}'
}

bytes_to_mb() {
    local bytes="$1"
    echo "scale=2; $bytes / 1048576" | bc
}

user_exists() {
    local username="$1"
    id "$username" &>/dev/null
}

get_current_user() {
    whoami
}

read_config_file() {
    local config_path="$1"
    if file_exists "$config_path"; then
        source "$config_path"
        return 0
    fi
    return 1
}

get_file_modification_time() {
    local file_path="$1"
    stat -f%Sm -t "%Y-%m-%d %H:%M:%S" "$file_path" 2>/dev/null || stat -c%y "$file_path" 2>/dev/null
}

count_files_in_directory() {
    local dir_path="$1"
    local pattern="$2"
    find "$dir_path" -maxdepth 1 -name "$pattern" -type f | wc -l | tr -d ' '
}

find_largest_file() {
    local dir_path="$1"
    local pattern="$2"
    find "$dir_path" -maxdepth 1 -name "$pattern" -type f -exec ls -l {} \; 2>/dev/null | sort -k5 -rn | head -n1 | awk '{print $NF}'
}
