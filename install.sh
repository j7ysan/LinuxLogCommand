#!/bin/bash

## CIS-341 Log Rotation System - Installation Script

set -e

SRC_CONFIG_FILE="./app/resources/log.cfg"
SRC_DEPLOYMENT_DIR="./app/deployment/etc/"
SRC_CODE_DIR="./app/src/"

INSTALL_PATH="/usr/local/bin/log-rotation"
CONFIG_INSTALL_PATH="/etc/log-rotation"
CONFIG_FILE_NAME="log.cfg"
CONFIG_FILE_PATH="$CONFIG_INSTALL_PATH/$CONFIG_FILE_NAME"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root (use sudo)"
   exit 1
fi

# Read configuration
source "$SRC_CONFIG_FILE"

echo "Starting installation..."

# Create user if doesn't exist
if ! id "$LOGMANAGER_USER" &>/dev/null; then
    echo "Creating user '$LOGMANAGER_USER'..."
    useradd -r -s /bin/bash "$LOGMANAGER_USER"
fi

# Create directories
mkdir -p "$LOG_DIR"

# Copy deployment files
echo "Copying system files..."
cp -r "$SRC_DEPLOYMENT_DIR" /

# Copy scripts
echo "Installing log rotation scripts..."
cp "$SRC_CODE_DIR"*.sh "$INSTALL_PATH/"
chmod +x "$INSTALL_PATH/"*.sh

# Copy config
cp "$SRC_CONFIG_FILE" "$CONFIG_INSTALL_PATH"

# Create log directory for status log
mkdir -p /var/log

# Set ownership
chown -R "$LOGMANAGER_USER:$LOGMANAGER_USER" "$LOG_DIR"
chown -R "$LOGMANAGER_USER:$LOGMANAGER_USER" "$INSTALL_PATH/"
chown "$LOGMANAGER_USER:$LOGMANAGER_USER" "$CONFIG_INSTALL_PATH"

# Reload and start systemd timer
echo "Enabling systemd timer..."
systemctl daemon-reload
systemctl enable log-rotation.timer
systemctl restart log-rotation.timer

echo "Installation complete!"
echo " "
systemctl status log-rotation.timer --no-pager | head -n 10
