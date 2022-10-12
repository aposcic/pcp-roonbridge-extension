#!/bin/busybox ash

EXTENSION_NAME=roonbridge

. /etc/init.d/tc-functions
. /var/www/cgi-bin/pcp-functions

# we use BusyBox and specify the TARGET var
useBusybox
TARGET=$(cat /etc/sysconfig/backup_device)

echo "[pcp-uninstall-roonbridge] Uninstalling Roon Bridge extension..."

# mark extension for deletion
sudo -u tc tce-audit builddb
sudo -u tc tce-audit delete $EXTENSION_NAME

# clear the user command
pcp_write_var_to_config USER_COMMAND_1 ""

# remove directores from piCore backup/persistence
sed -i '/var\/roon\/RoonBridge/d' /opt/.filetool.lst
sed -i '/var\/roon\/RAATServer/d' /opt/.filetool.lst

# remove directories from piCore exclusion list
sed -i '/var\/roon\/RoonBridge\/Logs/d' /opt/.xfiletool.lst
sed -i '/var\/roon\/RAATServer\/Logs/d' /opt/.xfiletool.lst
sed -i '/opt\/RoonBridge/d' /opt/.xfiletool.lst

# remove Roon Bridge dist directory so that it doesn't get persisted
rm -r /opt/RoonBridge

# back up changes to SD card
echo "[pcp-uninstall-roonbridge] Backing up data to SD card..."
filetool.sh -b

echo "[pcp-uninstall-roonbridge] Roon Bridge uninstallation finished. Please restart your system."
