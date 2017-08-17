#!/usr/bin/env bash
sudo apt-get install zsh links2 network-manager sshpass xinit xserver-xorg-legacy x11-xserver-utils moreutils # Install deps
sudo systemctl start NetworkManager # Start NetworkManager
echo -e "allowed_users=console\nneeds_root_rights=yes" | sudo tee /etc/X11/Xwrapper.config # Enable xinit for non-root users
echo -e "xsetroot -solid darkgrey &\nsetxkbmap -option \"terminate:ctrl_alt_bksp\"" | sudo tee /root/.xinitrc