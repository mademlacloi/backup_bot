#!/bin/bash
sed -i '/alias backuppanel=/d' ~/.bashrc
sed -i '/alias backup=/d' ~/.bashrc
echo "alias backuppanel='/opt/backup_panel.sh'" >> ~/.bashrc
echo "Alias fixed. Please run 'source ~/.bashrc' or restart your terminal."
