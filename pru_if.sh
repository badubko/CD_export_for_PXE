#! /bin/bash


VERSION="1.1"
WHERE_TO_MOUNT="/var/lib/tftpboot/"
FSTAB="/etc/fstab"
EXPORTS="/etc/exports"
LOCATION_OF_MENU="/var/lib/tftpboot/debian-installer/amd64/boot-screens/"
MENU_F_NAME="menu.cfg"

MOUNT_OPTIONS_STRING='udf,iso9660 user,loop 0 0'
EXPORT_OPTIONS_STRING='*(ro,sync,no_wdelay,insecure_locks,no_root_squash,insecure,no_subtree_check)'

STRING_TO_CLEAR_IN_FAN_NAME="-desktop-amd64"

INITRD="/casper/initrd"
VMLINUZ="/casper/vmlinuzt" 

FANTASY_NAME="UB_20"

# Verify that mounted CD has requiered files for booting it.
# kubuntu-18.04.2/casper/vmlinuz
#  kubuntu-18.04.2/casper/initrd 

if  [   ! -f  ${WHERE_TO_MOUNT}${FANTASY_NAME}${VMLINUZ} ]  ||  [  ! -f  ${WHERE_TO_MOUNT}${FANTASY_NAME}${INITRD}  ]
then
		echo "Either "
		echo "         ${WHERE_TO_MOUNT}${FANTASY_NAME}${VMLINUZ}  "
		echo "OR"
		echo "      ${WHERE_TO_MOUNT}${FANTASY_NAME}${INITRD}  "
		echo "Are not present in mounted image"
		exit
fi
