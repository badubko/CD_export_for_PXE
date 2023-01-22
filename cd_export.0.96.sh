#!  /bin/bash


# Usage:
# cd_export  cd_to_export    [fantasy_name_to_mount]

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
VMLINUZ="/casper/vmlinuz" 

#----------------------------------------------------------------------------------------------------------------------------------------------

if [ ${USER} != "root" ]
then
	echo "Must be root to run this script"
	exit
fi

if [ $# -eq 0 ]
then
	echo  -e  "\nUSAGE: $0  cd_to_export   [fantasy_name_to_use_for_mounting]\n"
	exit
fi	

CD_TO_EXPORT="${1}"

FANTASY_NAME="${2}"
   


if [ ! -f "${CD_TO_EXPORT}" ]
then
  echo "$0: requested CD doesn't exist : ${CD_TO_EXPORT}" 
  exit
fi

# Verify that it has an    .iso extension

FILE_EXT="${CD_TO_EXPORT##*.}" 	# get extension
FILE_EXT="${FILE_EXT,,}" 

# echo $CD_TO_EXPORT $FILE_EXT

if [  ${FILE_EXT} != "iso"  ]
then
	echo "${CD_TO_EXPORT} is not an iso image"
	exit
fi


   
if [[ -z "${FANTASY_NAME}" ]]
then
   echo "Fantasy name not set."
   # Generate fantasy name from CD's name W/O the extension.
   
   FANTASY_NAME=${CD_TO_EXPORT##*/}

   FANTASY_NAME=${FANTASY_NAME%.*}
   
   FANTASY_NAME=${FANTASY_NAME/${STRING_TO_CLEAR_IN_FAN_NAME}/}
   
else
   # Make sure that Fantasy name doesn't contain any directories...
      FANTASY_NAME=${FANTASY_NAME##*/}
fi

echo "Fantasy Name to be used: " $FANTASY_NAME

# Check if this image is already present in ${FSTAB}

LINE_COUNT=$( grep  -c "${CD_TO_EXPORT}"  < ${FSTAB} ) 

 if [ ${LINE_COUNT} -gt 0 ]
then
   # Check if there is a line  containing CD_TO_EXPORT that is not a comment 
   LINE_IN_FSTAB=$( egrep  -v  -e  "^#.*" < ${FSTAB} | egrep  -e  "${CD_TO_EXPORT}" | sed  -r -e 's/ +/ /g')
   echo -e "\n"
   echo "Line found in ${FSTAB} is: "
   echo -e  "${LINE_IN_FSTAB} \n"
   if [  $?  == 0 ] 
   then
		# echo "${CD_TO_EXPORT}" " Already present in fstab and not a comment"
		# Check if FANTASY_NAME is the same as in fstab...
		
		MOUNT_NAME_FSTAB=$( cut -d " " -f 2 <<<${LINE_IN_FSTAB} )
		
#		MOUNT_NAME_FSTAB=$( echo -n  "${LINE_IN_FSTAB}" |  cut -d ' ' -f 2 )

		# echo ${MOUNT_NAME_FSTAB}
		if  [  "${MOUNT_NAME_FSTAB}" != ${WHERE_TO_MOUNT}${FANTASY_NAME}  ]
		then
				echo "Fantasy name  is not the same as mount point in ${FSTAB} Correct this..."
		        exit
		fi        
   else
		echo "Line present as a comment. in fstab Please correct this"
        exit		
   fi 
else
        echo "Adding line to fstab"
        echo -e "#     \n"  >>${FSTAB}
        printf "%s  %s  %s \n "  ${CD_TO_EXPORT}  ${WHERE_TO_MOUNT}${FANTASY_NAME} "${MOUNT_OPTIONS_STRING}" >>${FSTAB}
fi

exit


# 
# Verify if it's already mounted

mount | grep   -q  "${CD_TO_EXPORT}" 
 
 if [ $? -eq 0 ]
then
   echo "${CD_TO_EXPORT}" " Already mounted..."
   # Determine Fastasy name used to mount
	MOUNT_NAME=$( mount | grep   "${CD_TO_EXPORT}" | sed  -r -e 's/ +/ /g' | cut -d " " -f 3 )
	MOUNT_NAME=${MOUNT_NAME##*/}
	# echo $MOUNT_NAME
	if [ ${MOUNT_NAME}  !=  ${FANTASY_NAME} ]
	then
	   echo "Mount_name  ${MOUNT_NAME} !=  ${FANTASY_NAME}"
	   echo "Check this..."
	   exit
	 fi
else
   echo "Mount it!"  
   # FInd if target directory exists
   if [  ! -d ${WHERE_TO_MOUNT}${FANTASY_NAME} ]
   then
		mkdir ${WHERE_TO_MOUNT}${FANTASY_NAME}
		if  [ $? != 0 ]
		then
			echo "Target directory creation failed:  ${WHERE_TO_MOUNT}${FANTASY_NAME}" 
			exit
		fi	
	fi		
   mount --source  ${CD_TO_EXPORT} -o 'loop'
fi


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
		
	    echo "Umounting image...${CD_TO_EXPORT}"
	    umount ${CD_TO_EXPORT}
		
		echo "Removing line that contains ${FANTASY_NAME} from ${FSTAB}"
		# Deleting the line that contains ${FANTASY_NAME}
		sed -i -e "/${FANTASY_NAME}/d" /etc/fstab
		exit
fi


# Verify if it is already en /etc/exports
# Use FANTASY_NAME from here onwards

grep  -q "${FANTASY_NAME}"  < /etc/exports 

 if [ $? -eq 0 ]
then
   # Check if the line is not a comment
   grep -q  -e  "^#.*${FANTASY_NAME}"  < /etc/exports
   if [  $?  != 0 ] 
   then
		echo "${FANTASY_NAME}" " Already present in exports and not a comment"
   else
		echo "Line present as a comment in /etc/exports. Please correct this"
        exit		
   fi 
else
          echo "Adding line to exports"
          echo -e "#     \n"  >>/etc/exports
         printf "%s  %s  %s \n "  ${WHERE_TO_MOUNT}${FANTASY_NAME} ${EXPORT_OPTIONS_STRING} >>/etc/exports
         
fi

# Verify is it's already exported

showmount -e localhost | grep -q "${WHERE_TO_MOUNT}${FANTASY_NAME}"

 if [ $? -eq 0 ]
then
   echo "${WHERE_TO_MOUNT}${FANTASY_NAME}" " Already exported..."
 else
   echo "Exporting"  
   exportfs -r
fi

# Add corresponding lines to PXE boot menu

# Strings for the menu entries...  We may need some of this data at this step

MY_SERVER_IP="192.168.1.130"
MENU_STRING1="APPEND  root=/dev/nfs boot=casper netboot=nfs ip=dhcp "
MENU_STRING2=" nfsroot=${MY_SERVER_IP}:${WHERE_TO_MOUNT}${FANTASY_NAME} "
MENU_STRING3="initrd=${FANTASY_NAME}/casper/initrd  no-quiet splash toram ---"


#
echo "#" 										 														 >>${LOCATION_OF_MENU}${MENU_F_NAME}
echo "LABEL ${FANTASY_NAME}"  														 >>${LOCATION_OF_MENU}${MENU_F_NAME}
echo  "KERNEL ${FANTASY_NAME}/casper/vmlinuz" 							 >>${LOCATION_OF_MENU}${MENU_F_NAME}
echo  "${MENU_STRING1}${MENU_STRING2}${MENU_STRING3}"  >>${LOCATION_OF_MENU}${MENU_F_NAME}
 
