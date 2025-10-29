#!/bin/bash

## CIS-341 Log Rotation System - Installation Script

set -e

CONFIG_FILE="./app/resources/log.cfg"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root (use sudo)"
   exit 1
fi

# Read configuration
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Configuration file not found: $CONFIG_FILE"
    exit 1
fi

source "$CONFIG_FILE"

echo "Starting installation..."

# Create user if doesn't exist
if ! id "$ZIP_USER" &>/dev/null; then
    echo "Creating user '$ZIP_USER'..."
    useradd -r -s /bin/bash "$ZIP_USER"
fi

# Create directories
mkdir -p "$LOG_DIR"

# Copy deployment files
echo "Copying system files..."
cp -r "./app/deployment/etc/" /

# Copy scripts
echo "Installing log rotation scripts..."
cp "./app/src/util.sh" /usr/local/bin/
cp "./app/src/functions.sh" /usr/local/bin/
cp "./app/src/log-rotation.sh" /usr/local/bin/
chmod +x /usr/local/bin/util.sh
chmod +x /usr/local/bin/functions.sh
chmod +x /usr/local/bin/log-rotation.sh

# Copy config if doesn't exist
CONFIG_INSTALL_PATH="/course_project/log.cfg"
if [[ ! -f "$CONFIG_INSTALL_PATH" ]]; then
    cp "./app/resources/log.cfg" "$CONFIG_INSTALL_PATH"
fi

# Create log directory for status log
mkdir -p /var/log

# Set ownership
chown -R "$ZIP_USER:$ZIP_USER" "$LOG_DIR"
chown "$ZIP_USER:$ZIP_USER" "$CONFIG_INSTALL_PATH"
chown "$ZIP_USER:$ZIP_USER" /usr/local/bin/util.sh
chown "$ZIP_USER:$ZIP_USER" /usr/local/bin/functions.sh
chown "$ZIP_USER:$ZIP_USER" /usr/local/bin/log-rotation.sh

# Reload and start systemd timer
echo "Enabling systemd timer..."
systemctl daemon-reload
systemctl enable log-rotation.timer
systemctl restart log-rotation.timer

echo "Installation complete!"
systemctl status log-rotation.timer --no-pager | head -n 10
