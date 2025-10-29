#!/usr/bin/env bats

TEST_DIR=""
TEST_LOG_DIR=""
TEST_CONFIG=""
TEST_STATUS_LOG=""

setup() {
    TEST_DIR="$(mktemp -d)"
    TEST_LOG_DIR="$TEST_DIR/logs"
    TEST_CONFIG="$TEST_DIR/log.cfg"
    TEST_STATUS_LOG="$TEST_DIR/status.log"
    mkdir -p "$TEST_LOG_DIR"
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "Shows help with --help flag" {
    run ../src/log-rotation.sh --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "USAGE:" ]]
}

@test "Zips log files and removes originals" {
    cat > "$TEST_CONFIG" <<EOF
LOG_DIR="$TEST_LOG_DIR"
OWN_LOG="$TEST_STATUS_LOG"
LOGMANAGER_USER="$(whoami)"
DELEGATED_USER=""
SIZE_WARNING_THRESHOLD_MB=100
ZIP_RETENTION_DAYS=14
EOF
    
    echo "test log content" > "$TEST_LOG_DIR/test.log"
    
    run ../src/log-rotation.sh --config "$TEST_CONFIG"
    
    [ "$status" -eq 0 ]
    [ ! -f "$TEST_LOG_DIR/test.log" ]
    [ $(find "$TEST_LOG_DIR" -name "*.zip" | wc -l) -gt 0 ]
}

@test "Creates status log file" {
    cat > "$TEST_CONFIG" <<EOF
LOG_DIR="$TEST_LOG_DIR"
OWN_LOG="$TEST_STATUS_LOG"
LOGMANAGER_USER="$(whoami)"
SIZE_WARNING_THRESHOLD_MB=100
ZIP_RETENTION_DAYS=14
EOF
    
    echo "test" > "$TEST_LOG_DIR/test.log"
    
    run ../src/log-rotation.sh --config "$TEST_CONFIG"
    
    [ "$status" -eq 0 ]
    [ -f "$TEST_STATUS_LOG" ]
    grep -q "Log rotation started" "$TEST_STATUS_LOG"
}

@test "Rejects unauthorized user" {
    cat > "$TEST_CONFIG" <<EOF
LOG_DIR="$TEST_LOG_DIR"
OWN_LOG="$TEST_STATUS_LOG"
LOGMANAGER_USER="unauthorizeduser"
SIZE_WARNING_THRESHOLD_MB=100
ZIP_RETENTION_DAYS=14
EOF
    
    run ../src/log-rotation.sh --config "$TEST_CONFIG"
    
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Unauthorized" ]]
}

@test "CLI parameters override config" {
    cat > "$TEST_CONFIG" <<EOF
LOG_DIR="/some/other/path"
OWN_LOG="$TEST_STATUS_LOG"
LOGMANAGER_USER="$(whoami)"
SIZE_WARNING_THRESHOLD_MB=100
ZIP_RETENTION_DAYS=14
EOF
    
    echo "test" > "$TEST_LOG_DIR/test.log"
    
    run ../src/log-rotation.sh --config "$TEST_CONFIG" --dir "$TEST_LOG_DIR"
    
    [ "$status" -eq 0 ]
    [ ! -f "$TEST_LOG_DIR/test.log" ]
}
