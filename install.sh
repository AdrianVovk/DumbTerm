#!/usr/bin/env bash
if [ `tty | grep -o -P '\d'` = $1 ]; then
   echo "[WARN] It seems like you are trying to install this tool to /dev/tty$1, but you are currently using it."
   echo "[WARN] Continuing with this installation will log you out of this terminal session. Press any key to continue or press ^C to cancel"
   read -srn1 # Pause for input
fi
echo "---------------------- Installing DumbTerm ----------------------"
sudo cp ./DumbTerm.sh /opt/DumbTerm.sh
echo -n "Update Location: "; echo "`pwd`" | sudo tee /opt/DumbTermInstall
sudo mkdir -p /etc/systemd/system/getty@tty$1.service.d
sudo cp ./Systemd.conf /etc/systemd/system/getty@tty$1.service.d/override.conf
sudo systemctl daemon-reload
sudo systemctl restart getty@tty$1.service
echo "Try to log into tty$1 to see if it worked"
echo "----------------------------- Done -----------------------------"