#!/bin/busybox ash

# define extension and extension upgrade dirs
TCEDIR=/etc/sysconfig/tcedir
EXTENSION_DIR=${TCEDIR}/optional
EXTENSION_UPGRADE_DIR=${EXTENSION_DIR}/upgrade
EXTENSION_NAME=roonbridge

# load some useful functions
. /etc/init.d/tc-functions
. /var/www/cgi-bin/pcp-functions

# we use BusyBox
useBusybox

# load the squash squashfs-tools extensions
sudo -u tc tce-load -wi squashfs-tools.tcz

# do everything in the /tmp directory
cd /tmp || exit

# download Roon Bridge package and unpack it
wget -O - http://download.roonlabs.com/updates/stable/RoonBridge_linuxarmv7hf.tar.bz2 | tar -jx

# move the Roon Bridge folder to conform with the desired extension tree
mkdir -p ${EXTENSION_NAME}/opt
mv RoonBridge ${EXTENSION_NAME}/opt

# make extension
mksquashfs ${EXTENSION_NAME} ${EXTENSION_NAME}.tcz

# we're either installing (1) or updating (2)
if [ ! -e /opt/RoonBridge ]; then
  # move the extension to the main extension dir
  mv ${EXTENSION_NAME}.tcz ${EXTENSION_DIR}
  
  # add dependency file
  cat <<EOF > ${EXTENSION_DIR}/${EXTENSION_NAME}.tcz.dep
pcp-ffmpeg.tcz
EOF

  # add to bootlist
  sed -i "/${EXTENSION_NAME}.tcz/d" ${TCEDIR}/onboot.lst
  echo "${EXTENSION_NAME}.tcz" >>${TCEDIR}/onboot.lst

  # create the configuration/data directories for Roon
  mkdir -p /var/roon/RoonBridge/Settings
  echo AskAlways > /var/roon/RoonBridge/Settings/update_mode
  mkdir -p /var/roon/RAATServer
  
  # write the Roon Bridge launch command to User Command 1
  pcp_write_var_to_config USER_COMMAND_1 "%2fopt%2fRoonBridge%2fstart.sh"
  
  # make sure we include Roon data in the piCore backup...
  sed -i '/\/var\/roon\/RoonBridge/d' /opt/.filetool.lst
  sed -i '/\/var\/roon\/RAATServer/d' /opt/.filetool.lst
  echo '/var/roon/RoonBridge' >>/opt/.filetool.lst
  echo '/var/roon/RAATServer' >>/opt/.filetool.lst

  # ... but not the log folders
  sed -i '/\/var\/roon\/RoonBridge\/Logs/d' /opt/.xfiletool.lst
  sed -i '/\/var\/roon\/RAATServer\/Logs/d' /opt/.xfiletool.lst
  echo '/var/roon/RoonBridge/Logs' >>/opt/.xfiletool.lst
  echo '/var/roon/RAATServer/Logs' >>/opt/.xfiletool.lst
else
  # move the extension the extension upgrade dir
  mv ${EXTENSION_NAME}.tcz ${EXTENSION_UPGRADE_DIR}
fi

filetool.sh -b

