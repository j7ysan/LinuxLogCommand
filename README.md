## CIS-341 Log Rotation System

The purpose of this project is to present a command in Linux that showcases
logs, filters logs, cleans logs, and more depending on their timestamp, size, etc.

## What It Does
Automatically zips .log files in a set folder every 2 days.

Deletes zipped logs that are older than 14 days.

Keeps a log of its own to track what it did.

Warns if the total log folder size gets too big (over 100 MB by default).

Only allows a specific user (logmanager) to run it, but you can delegate to others.

Lets you change basic settings in a config file or through command-line options.

### Installation

The installation process is automated using the `install.sh` script, which performs all necessary setup steps to enable the log-rotation service.

1. Clone or download this repository.
2. Run: `sudo ./install.sh`.

## Configuration
There’s a file called log.cfg where you set things like:

Where the logs are stored (LOG_DIR)

Who can run the script (LOGMANAGER_USER)

How big the folder can get before warning (SIZE_WARNING_THRESHOLD_MB)

How long to keep zipped files (ZIP_RETENTION_DAYS)

### Testing

The project includes automated tests using BATS.

**Prerequisites:** Install BATS
```bash
# macOS
brew install bats-core

# Linux
sudo apt install bats
```

**Run tests:**
```bash
cd app/test
bats log-rotation.bats
```

### Usage

## Logs Included
This repo includes sample logs (sample.log, application.log, etc.) for testing the script.

#### View Logs

```bash
sudo journalctl -u log-rotation.service
sudo journalctl -u log-rotation.timer
```


