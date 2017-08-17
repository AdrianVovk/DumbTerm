#!/usr/bin/env bash
echo "---------------------- Resetting tty$1 -----------------------"
sudo rm -rf /etc/systemd/system/getty@tty$1.service.d
sudo systemctl daemon-reload
sudo systemctl restart getty@tty$1.service
echo "Try logging into tty$1 to see if it was reset back to default"
echo "Note: graphical glitches can occur in some situations. Logging in or a simple reboot should fix the issue"
echo "---------------------------- Done ----------------------------"