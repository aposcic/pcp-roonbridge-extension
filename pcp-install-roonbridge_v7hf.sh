#!/bin/busybox ash

# define main extension and extension upgrade dirs
TCEDIR=/etc/sysconfig/tcedir
EXTENSION_DIR=${TCEDIR}/optional
EXTENSION_UPGRADE_DIR=${EXTENSION_DIR}/upgrade
EXTENSION_NAME=roonbridge

# load some useful functions
. /etc/init.d/tc-functions
. /var/www/cgi-bin/pcp-functions

# we use BusyBox and specify the TARGET var
useBusybox
TARGET=$(cat /etc/sysconfig/backup_device)

echo "[pcp-install-roonbridge] Settings things up..."

# load the squashfs-tools extensions
sudo -u tc tce-load -wil squashfs-tools.tcz

# do everything in the /tmp directory
cd /tmp || exit

# download Roon Bridge package and unpack it
echo "[pcp-install-roonbridge] Downloading Roon Bridge package..."
wget -O - https://download.roonlabs.net/builds/RoonBridge_linuxarmv7hf.tar.bz2 | tar -jx

# move the Roon Bridge folder to conform with the desired extension tree
mkdir -p ${EXTENSION_NAME}/opt
mv RoonBridge ${EXTENSION_NAME}/opt

# create custom startup script
cat <<EOF >  ${EXTENSION_NAME}/opt/RoonBridge/pcp-start.sh
#!/bin/busybox ash

. /var/www/cgi-bin/pcp-functions

if [ "\$#" -eq "1" ] && [ "\$1" = "-d" ]; then
  exit 0
elif [ "\$#" -eq "1" ] && [ "\$1" = "-c" ]; then
  . \$PCPCFG
  if [ "\$SQUEEZELITE" = "yes" ]; then
    exit 0
  else
    ROON_DATAROOT=/var/roon ROON_ID_DIR=/var/roon /opt/RoonBridge/start.sh >/dev/null 2>\&1
  fi
else
  ROON_DATAROOT=/var/roon ROON_ID_DIR=/var/roon /opt/RoonBridge/start.sh >/dev/null 2>\&1
fi

EOF

# make the script executable
chmod +x ${EXTENSION_NAME}/opt/RoonBridge/pcp-start.sh

# make extension
echo "[pcp-install-roonbridge] Creating Roon Bridge pCP extension..."
mksquashfs ${EXTENSION_NAME} ${EXTENSION_NAME}.tcz

# we're either installing (1) or updating (2)
if [ ! -e /opt/RoonBridge ]; then
  echo "[pcp-install-roonbridge] Installing Roon Bridge extension..."

  # move the extension to the main extension dir
  mv ${EXTENSION_NAME}.tcz ${EXTENSION_DIR}

  # add to bootlist
  sed -i "/${EXTENSION_NAME}.tcz/d" ${TCEDIR}/onboot.lst
  echo "${EXTENSION_NAME}.tcz" >>${TCEDIR}/onboot.lst

  # create the configuration/data directories for Roon
  mkdir -p /var/roon/RoonBridge/Settings
  echo AskAlways > /var/roon/RoonBridge/Settings/update_mode
  mkdir -p /var/roon/RAATServer
  
  # write the Roon Bridge launch command to User Command 1
  pcp_write_var_to_config USER_COMMAND_1 "%2fopt%2fRoonBridge%2fpcp-start.sh"
  
  # make sure we include Roon data in the piCore backup...
  sed -i '/var\/roon\/RoonBridge/d' /opt/.filetool.lst
  sed -i '/var\/roon\/RAATServer/d' /opt/.filetool.lst
  echo 'var/roon/RoonBridge' >>/opt/.filetool.lst
  echo 'var/roon/RAATServer' >>/opt/.filetool.lst

  # ... but not the log folders...
  sed -i '/var\/roon\/RoonBridge\/Logs/d' /opt/.xfiletool.lst
  sed -i '/var\/roon\/RAATServer\/Logs/d' /opt/.xfiletool.lst
  echo 'var/roon/RoonBridge/Logs' >>/opt/.xfiletool.lst
  echo 'var/roon/RAATServer/Logs' >>/opt/.xfiletool.lst
  
  # ... and definitely not the RoonBridge distribution folder
  sed -i '/opt\/RoonBridge/d' /opt/.xfiletool.lst
  echo 'opt/RoonBridge' >>/opt/.xfiletool.lst
  
else
  echo "[pcp-install-roonbridge] Updating Roon Bridge extension..."

  # move the extension to the extension upgrade dir
  mkdir -p ${EXTENSION_UPGRADE_DIR}
  mv ${EXTENSION_NAME}.tcz ${EXTENSION_UPGRADE_DIR}
fi

# clean up
rm -r /tmp/${EXTENSION_NAME}

# back up changes to SD card
echo "[pcp-install-roonbridge] Backing up data to SD card..."
filetool.sh -b

echo "[pcp-install-roonbridge] Roon Bridge installation/update finished. Please restart your system."
