#!/usr/bin/env bash

# Execute true script
cd ArchScripts/
./arch_install.sh
cd ..
echo "#################################"
echo "#    ОС установлено после       #" 
echo "# перезагрзуки извликите флэшку #"
echo "#################################"
sleep 2
reboot
