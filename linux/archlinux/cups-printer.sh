#!/bin/sh

sudo pacman -S cups ghostscript gsfonts cups-pdf gutenprint --noconfirm
sudo systemctl start org.cups.cupsd.service
sudo usermod -aG cups $(whoami)
sudo newgrp cups

echo -e "it will open default browser and visit printer page http://localhost:631. \n
Administration > login \n
username:root  \n
password:  (root's password)
"

xdg-open 'http://localhost:631'
