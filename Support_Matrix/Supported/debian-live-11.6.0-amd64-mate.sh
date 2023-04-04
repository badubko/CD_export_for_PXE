#! /bin/bash

BOOT_STRING="live"

    if [ -f  ${WHERE_TO_MOUNT}${FANTASY_NAME}/${BOOT_STRING}/vmlinuz* ]
	then
		VMLINUZ_STRING=$(ls ${WHERE_TO_MOUNT}${FANTASY_NAME}/${BOOT_STRING}/vmlinuz*)
		VMLINUZ_STRING="/${BOOT_STRING}/${VMLINUZ_STRING##*/}"
		echo "vmlinux string: ${VMLINUZ_STRING}"
	else
			echo "NO vmlinuz exists"
			exit
	fi
	
	if [ -f  ${WHERE_TO_MOUNT}${FANTASY_NAME}/${BOOT_STRING}/initrd* ]
	then
		INITRD_STRING=$(ls ${WHERE_TO_MOUNT}${FANTASY_NAME}/${BOOT_STRING}/initrd*)
		INITRD_STRING="${INITRD_STRING##*/}"
			
	else
			echo "NO initrd exists"
			exit
	fi
				
	INITRD_STRING="${BOOT_STRING}/${INITRD_STRING}"
	echo "initrd string: ${INITRD_STRING}"
	MENU_STRING1="APPEND  root=/dev/nfs boot=${BOOT_STRING} netboot=nfs ip=dhcp "
	MENU_STRING2=" nfsroot=${MY_SERVER_IP}:${WHERE_TO_MOUNT}${FANTASY_NAME} "
	MENU_STRING3="initrd=${DELTA}${FANTASY_NAME}/${INITRD_STRING}  no-quiet  toram ---"
