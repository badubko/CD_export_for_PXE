#! /bin/bash

# gparted

BOOT_STRING="live"
	VMLINUZ_STRING="/live/vmlinuz"
	INITRD_STRING="/live/initrd.img"
	MENU_STRING1="APPEND  root=/dev/nfs boot=${BOOT_STRING} netboot=nfs ip=dhcp "
	MENU_STRING2=" nfsroot=${MY_SERVER_IP}:${WHERE_TO_MOUNT}${FANTASY_NAME} "
	MENU_STRING3="initrd=${DELTA}${FANTASY_NAME}${INITRD_STRING}  union=overlay  config components no-quiet  toram ---"
