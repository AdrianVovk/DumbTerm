#!/usr/bin/env bash
echo "---------------------- Installing DumbTerm ----------------------"
sudo cp ./DumbTerm.sh /opt/DumbTerm.sh
echo -n "Update Location:"; echo "`pwd`" | sudo tee /opt/DumbTermInstall
sudo mkdir -p /etc/systemd/system/getty@tty$1.service.d
sudo cp ./Systemd.conf /etc/systemd/system/getty@tty$1.service.d/override.conf
sudo systemctl daemon-reload
sudo systemctl restart getty@tty$1.service
echo "Try to log into tty$1 to see if it worked"
echo "----------------------------- Done -----------------------------"