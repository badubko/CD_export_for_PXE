#! /bin/bash

if [ ${USER} != "root" ]
then
	echo "Must be root to run this script"
	exit
fi

LIST_TO_MOUNT=$(grep "/var/lib/tftpboot" </etc/fstab | cut -d " " -f 1)

for DIR in ${LIST_TO_MOUNT}
do
     #  echo $DIR 
	 mount  -v  ${DIR}

done
	
exit
