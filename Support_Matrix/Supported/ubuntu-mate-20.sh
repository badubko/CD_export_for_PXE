#! /bin/bash

    BOOT_STRING="casper"
	VMLINUZ_STRING="/casper/vmlinuz"
	INITRD_STRING="/casper/initrd"
	MENU_STRING1="APPEND  root=/dev/nfs boot=${BOOT_STRING} netboot=nfs ip=dhcp "
	MENU_STRING2=" nfsroot=${MY_SERVER_IP}:${WHERE_TO_MOUNT}${FANTASY_NAME} "
	MENU_STRING3="initrd=${DELTA}${FANTASY_NAME}${INITRD_STRING}  no-quiet  toram ---"
