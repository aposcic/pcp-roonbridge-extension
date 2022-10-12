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

# remove files from piCore backup/persistence
sed -i '/var\/roon\/RoonBridge/d' /opt/.filetool.lst
sed -i '/var\/roon\/RAATServer/d' /opt/.filetool.lst

# back up changes to SD card
echo "[pcp-uninstall-roonbridge] Backing up data to SD card..."
filetool.sh -b

# remove files from piCore exclusion list
# (this needs to happen AFTER backing up so that the excluded files don't get persisted)
sed -i '/var\/roon\/RoonBridge\/Logs/d' /opt/.xfiletool.lst
sed -i '/var\/roon\/RAATServer\/Logs/d' /opt/.xfiletool.lst
sed -i '/opt\/RoonBridge/d' /opt/.xfiletool.lst

echo "[pcp-uninstall-roonbridge] Roon Bridge uninstallation finished. Please restart your system."
