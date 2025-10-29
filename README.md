## CIS-341 Log Rotation System

The purpose of this project is to present a command in Linux that showcases
logs, filters logs, cleans logs, and more depending on their timestamp, size, etc.

### Installation

The installation process is automated using the `install.sh` script, which performs all necessary setup steps to enable the log-rotation service.

1. Clone or download this repository.
2. Run: `sudo ./install.sh`.

#### View Logs

```bash
sudo journalctl -u log-rotation.service
sudo journalctl -u log-rotation.timer
```


