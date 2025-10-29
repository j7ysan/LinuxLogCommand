#!/bin/bash

CONFIG_FILE="~/app/resources/log.cfg"
LOG_FILE="~/var/log/logservice.log"

# TASK 4:
# Service consuming its own configuration file for arguments.


# Checking to see if the configuration file exists in the system
# Looking for specifically log.cfg
if [ -f "$CONFIG_FILE" ]; then
	FOUND_CONFIG_FILE="$CONFIG_FILE"
	echo "Successful check.."
	echo "Configuration file found: $FOUND_CONFIG_FILE"
	echo "Consuming configuration file" >> "$FOUND_CONFIG_FILE"
else
	ERROR_CONFIG_FILE="$CONFIG_FILE"
	echo "Error occurred.."
	echo "Configuration file not found." 
	echo "Path attempted: $ERROR_CONFIG_FILE"
	exit 1
fi 

# TASK 5:
# Service creating its own log to monitor its own running status.

# Looking for the log file that we have for the service
if [ -f "$LOG_FILE" ]; then
	FOUND_LOG_FILE="$LOG_FILE"
	echo "Successful check.."
	echo "Log file for service found: $FOUND_LOG_FILE"
else
	ERROR_LOG_FILE="$LOG_FILE"
	echo "Error occurred.."
	echo "Log file not found."
	echo "Path attempted: $ERROR_LOG_FILE"
	exit 1
fi
	

# Appending its own log and current running status
journalctl -u log-rotation.service >> "$FOUND_LOG_FILE"
