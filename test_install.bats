#!/usr/bin/env bats

# Verify if the installation script worked correctly on your machine.

setup() {
    # Sourcing the config to get expected values
    source "./app/resources/log.cfg"
    
    INSTALL_PATH="/usr/local/bin/log-rotation"
    CONFIG_INSTALL_PATH="/etc/log-rotation"
}

@test "logmanager user exists" {
    id "$LOGMANAGER_USER"
}

@test "log directory exists with correct ownership" {
    [ -d "$LOG_DIR" ]

    # Check ownership
    owner=$(stat -c%U "$LOG_DIR" || stat -f%Su "$LOG_DIR")
    [ "$owner" = "$LOGMANAGER_USER" ]
}

@test "util.sh script is installed and executable" {
    [ -f "$INSTALL_PATH/util.sh" ]
    [ -x "$INSTALL_PATH/util.sh" ]
}

@test "functions.sh script is installed and executable" {
    [ -f "$INSTALL_PATH/functions.sh" ]
    [ -x "$INSTALL_PATH/functions.sh" ]
}

@test "log-rotation.sh script is installed and executable" {
    [ -f "$INSTALL_PATH/log-rotation.sh" ]
    [ -x "$INSTALL_PATH/log-rotation.sh" ]
}

@test "installation directory has correct ownership" {
    owner=$(stat -f%Su "$INSTALL_PATH" || stat -c%U "$INSTALL_PATH")
    
    [ "$owner" = "$LOGMANAGER_USER" ]
}

@test "config file is installed" {
    [ -f "$CONFIG_INSTALL_PATH/log.cfg" ]
}

@test "config directory has correct ownership" {
    owner=$(stat -f%Su "$CONFIG_INSTALL_PATH" || stat -c%U "$CONFIG_INSTALL_PATH")

    [ "$owner" = "$LOGMANAGER_USER" ]
}

@test "systemd service file exists" {
    [ -f "/etc/systemd/system/log-rotation.service" ]
}

@test "systemd timer file exists" {
    [ -f "/etc/systemd/system/log-rotation.timer" ]
}

@test "systemd timer is enabled" {
    systemctl is-enabled log-rotation.timer
}

@test "systemd timer is active" {
    systemctl is-active log-rotation.timer
}
