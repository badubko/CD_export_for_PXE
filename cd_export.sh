#!  /bin/bash


# Usage:
# cd_export  cd_to_export    [fantasy_name_to_mount]

show_usage ()
{
	echo  -e  "\nUSAGE: $0  cd_to_export   [fantasy_name_to_use_for_mounting]\n"
	cat <<!FINIS
    Version:  $VERSION
    This script will do all the operations needed to enable PXE boot from an
    iso image of a bootable linux cd,  passed as the first argument.
    
    1- After performing various checks, it will add it to ${FSTAB} 
    using as the mount point a  "Fantasy Name" either passed as a second argument 
    or created from the name of the iso image.
    If the iso image is not  already mounted, it is mounted.
    
    2- After performing various checks, the mount point is added to ${EXPORTS} and exported.
         
    3- Adds the corresponding lines to PXE boot menu
        ${LOCATION_OF_MENU}${MENU_F_NAME}
        
    Limitations:    
    In this version, the functionaliy of this scipt is limited only to bootable linux images.

!FINIS
return

}

#----------------------------------------------------------------------------------------------------------------------------------------------
basic_checks ()
{
if [ ${USER} != "root" ]
then
	echo "Must be root to run this script"
	exit
fi

if [  -z ${CD_TO_EXPORT}  ]
then
	show_usage
	exit
fi	


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

return

}

#----------------------------------------------------------------------------------------------------------------------------------------------
determine_os_type()
{
SUPPORTED_OS_TYPES=("ubuntu" "debian" "trisquel" "fedora" "gparted" "pop_os" "alma")

declare -A SUPPORT_MATRIX

SUPPORT_MATRIX[ubuntu]="SUPPORTED"

SUPPORT_MATRIX[debian]="SUPPORTED"

SUPPORT_MATRIX[trisquel]="SUPPORTED"

SUPPORT_MATRIX[pop_os]="SUPPORTED"

SUPPORT_MATRIX[alma]="NOT_SUPPORTED"

SUPPORT_MATRIX[fedora]="NOT_SUPPORTED"

# SUPPORT_MATRIX[fedora]="SUPPORTED"

SUPPORT_MATRIX[gparted]="SUPPORTED"

SUPPORT_MATRIX[haiku]="NOT_SUPPORTED"

for OS_TYPE in "${!SUPPORT_MATRIX[@]}"
do
	# Convert CD_TO_EXPORT to lowercase ( to be reviewed... )
	grep  ${OS_TYPE} <<<${CD_TO_EXPORT,,}
	if [ $? == 0 ]
	then
			case ${SUPPORT_MATRIX[${OS_TYPE}]} in
			"SUPPORTED")
				MENU_LINES_GENERATION="WRITE_MENU_LINES"
				break
				;;
			"DONT_WRITE_MENU_LINES")
				MENU_LINES_GENERATION="DONT_WRITE_MENU_LINES"
				break
				;;
			"NOT_SUPPORTED")
				echo "OS_TYPE: ${OS_TYPE} is NOT supported" 
				exit
				;;
			esac
	fi
done

echo "OS_TYPE is: ${OS_TYPE}"

return		
}

#----------------------------------------------------------------------------------------------------------------------------------------------
set_fantasy_name()
{
 	  
if [[ -z "${FANTASY_NAME}" ]]
then
   echo "Fantasy name not set."
   # Generate fantasy name from CD's name W/O the directories and the extension.
   
   FANTASY_NAME=${CD_TO_EXPORT##*/}

   FANTASY_NAME=${FANTASY_NAME%.*}
   
   for STRING_TO_CLEAR in ${STRING_TO_CLEAR_IN_FAN_NAME[@]}
   do
		FANTASY_NAME=${FANTASY_NAME/${STRING_TO_CLEAR}/}
   done
   
else
   # Make sure that Fantasy name doesn't contain any directories...
      FANTASY_NAME=${FANTASY_NAME##*/}
fi

echo "Fantasy Name to be used: " $FANTASY_NAME


return
}

#----------------------------------------------------------------------------------------------------------------------------------------------

verify_if_image_present_in_fstab()
{
# Check if this image is already present in ${FSTAB}

LINE_COUNT=$( grep  -c "${CD_TO_EXPORT}"  < ${FSTAB} ) 
TOTAL_NC_LINES=$( grep  -v  -e  "^#.*" < ${FSTAB} | grep -c  -e  "${CD_TO_EXPORT}" )
TOTAL_C_LINES=$( egrep    -e  "^#.*" < ${FSTAB} | grep -c  -e  "${CD_TO_EXPORT}" )

# echo $LINE_COUNT     $TOTAL_NC_LINES      $TOTAL_C_LINES


if  [  ${LINE_COUNT} -gt 0 ]
then
	if [  ${LINE_COUNT} -eq 1 ]
	then

		if  [ ${TOTAL_NC_LINES} -eq 1 ]   &&  [ ${TOTAL_C_LINES} -eq  0 ]
		then
			 ACTION="Verify_Fantasy"
		else
             ACTION="Inform_Add"
		fi

    else
 
       if  [ ${TOTAL_NC_LINES}  -ge  2  ] &&  [ ${TOTAL_C_LINES} -eq 0 ] 
       then
             ACTION="Inform_Stop"
       fi
 
       if  [ ${TOTAL_NC_LINES}  -eq  0 ]  &&  [ ${TOTAL_C_LINES} -ge  2 ] 
       then
             ACTION="Inform_Add"
       fi

		if [ ${TOTAL_NC_LINES}  -ge  1 ] &&  [ ${TOTAL_C_LINES} -ge  1 ] 
       then
             ACTION="Inform_Stop"
       fi
       
    fi
        
else
      ACTION="Add"
fi

 echo  "Action: $ACTION"


case ${ACTION} in

"Add" )
        echo "Adding line to ${FSTAB}"
		echo -e "#"  >>${FSTAB}
		printf "%s  %s  %s \n "  ${CD_TO_EXPORT}  ${WHERE_TO_MOUNT}${FANTASY_NAME} "${MOUNT_OPTIONS_STRING}" >>${FSTAB}
        ;;
       
"Inform_Add" )
		echo "${CD_TO_EXPORT}" " Already present in ${FSTAB} as a comment"
		echo "Adding line to fstab"
		echo -e "#"  >>${FSTAB}
		printf "%s  %s  %s \n "  ${CD_TO_EXPORT}  ${WHERE_TO_MOUNT}${FANTASY_NAME} "${MOUNT_OPTIONS_STRING}" >>${FSTAB}
          ;;
"Verify_Fantasy" )
        echo "${CD_TO_EXPORT}" " Already present in ${FSTAB} and not a comment"
		echo "Checking if FANTASY_NAME is the same as in ${FSTAB}..."
		LINE_IN_FSTAB=$( egrep  -v  -e  "^#.*" < ${FSTAB} | egrep  -e  "${CD_TO_EXPORT}" | sed  -r -e 's/ +/ /g')
		MOUNT_NAME_FSTAB=$( cut -d " " -f 2 <<<${LINE_IN_FSTAB} )

		# echo ${MOUNT_NAME_FSTAB}
		if  [  "${MOUNT_NAME_FSTAB}" != ${WHERE_TO_MOUNT}${FANTASY_NAME}  ]
		then
				echo "Fantasy name  is not the same as mount point in ${FSTAB} Correct this..."
		        exit
		fi        
          ;;   
"Inform_Stop" )
		  echo "${CD_TO_EXPORT}" " Already present in ${FSTAB} many times"
		  echo "Correct this..."
		  exit
          ;;
*)
		  echo "Non existent option"
		  exit
		  ;;
esac

}

#----------------------------------------------------------------------------------------------------------------------------------------------
verify_and_mount()
{
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
	
return
}


#----------------------------------------------------------------------------------------------------------------------------------------------
set_menu_strings ()
{
	
# This command is not reliable for this purpose as it can return more than 1 line...
# Evaluate other options later...

MY_SERVER_IP="$(hostname -I )"
MY_SERVER_IP=${MY_SERVER_IP% }

case  ${OS_TYPE} in
ubuntu)
    BOOT_STRING="casper"
	VMLINUZ_STRING="/casper/vmlinuz"
	INITRD_STRING="/casper/initrd"
	MENU_STRING1="APPEND  root=/dev/nfs boot=${BOOT_STRING} netboot=nfs ip=dhcp "
	MENU_STRING2=" nfsroot=${MY_SERVER_IP}:${WHERE_TO_MOUNT}${FANTASY_NAME} "
	MENU_STRING3="initrd=${DELTA}${FANTASY_NAME}${INITRD_STRING}  no-quiet  toram ---"

	verify_boot_files_exist_on_target
	
	return
	;;
	
debian)
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
	MENU_STRING3="initrd=${DELTA}${FANTASY_NAME}/${INITRD_STRING}  no-quiet splash toram ---"
	return
	;;
	
trisquel)
    BOOT_STRING="casper"
	VMLINUZ_STRING="/casper/vmlinuz"
	INITRD_STRING="/casper/initrd"
	MENU_STRING1="APPEND  root=/dev/nfs boot=${BOOT_STRING} netboot=nfs ip=dhcp "
	MENU_STRING2=" nfsroot=${MY_SERVER_IP}:${WHERE_TO_MOUNT}${FANTASY_NAME} "
	MENU_STRING3="initrd=${DELTA}${FANTASY_NAME}${INITRD_STRING}  no-quiet  toram ---"
	
	verify_boot_files_exist_on_target
	
	return
	;;
	
fedora)
    BOOT_STRING="images/pxeboot"
	VMLINUZ_STRING="/images/pxeboot/vmlinuz"
	INITRD_STRING="/images/pxeboot/initrd.img"
	MENU_STRING1="APPEND  root=/dev/nfs boot=${BOOT_STRING} netboot=nfs ip=dhcp "
	MENU_STRING2=" nfsroot=${MY_SERVER_IP}:${WHERE_TO_MOUNT}${FANTASY_NAME} "
	MENU_STRING3="initrd=${DELTA}${FANTASY_NAME}${INITRD_STRING}  no-quiet  toram ---"
	
	verify_boot_files_exist_on_target
	
	return
	;;	
gparted)
    BOOT_STRING="live"
	VMLINUZ_STRING="/live/vmlinuz"
	INITRD_STRING="/live/initrd.img"
	MENU_STRING1="APPEND  root=/dev/nfs boot=${BOOT_STRING} netboot=nfs ip=dhcp "
	MENU_STRING2=" nfsroot=${MY_SERVER_IP}:${WHERE_TO_MOUNT}${FANTASY_NAME} "
	MENU_STRING3="initrd=${DELTA}${FANTASY_NAME}${INITRD_STRING}  union=overlay  config components no-quiet  toram ---"
	
	verify_boot_files_exist_on_target
	
	return
	;;	
pop_os)
    BOOT_STRING="casper"
	VMLINUZ_STRING="/casper/vmlinuz.efi"
	INITRD_STRING="/casper/initrd.gz"
	MENU_STRING1="APPEND  root=/dev/nfs boot=${BOOT_STRING} netboot=nfs ip=dhcp "
	MENU_STRING2=" nfsroot=${MY_SERVER_IP}:${WHERE_TO_MOUNT}${FANTASY_NAME} "
	MENU_STRING3="initrd=${DELTA}${FANTASY_NAME}${INITRD_STRING}  no-quiet  toram ---"
	
	verify_boot_files_exist_on_target
	
	return
	;;
		
alma)
    BOOT_STRING="images/pxeboot"
	VMLINUZ_STRING="/images/pxeboot/vmlinuz"
	INITRD_STRING="/images/pxeboot/initrd.img"
	
	#BOOT_STRING="isolinux"
	#VMLINUZ_STRING="/isolinux/vmlinuz"
	#INITRD_STRING="/isolinux/initrd.img"
	
	
	MENU_STRING1="APPEND  root=/dev/nfs boot=${BOOT_STRING} netboot=nfs ip=dhcp "
	MENU_STRING2=" nfsroot=${MY_SERVER_IP}:${WHERE_TO_MOUNT}${FANTASY_NAME} "
	MENU_STRING3="initrd=${DELTA}${FANTASY_NAME}${INITRD_STRING}  no-quiet splash toram ---"
	
	verify_boot_files_exist_on_target
	
	return
	;;	
	
*)
	return
	;;
esac
	
return
}
#----------------------------------------------------------------------------------------------------------------------------------------------
verify_boot_files_exist_on_target ()
{

# Verify that mounted CD has required files for booting it.
# Example:
# CD mounted as  kubuntu-18.04.2
# Then 
# kubuntu-18.04.2/casper/vmlinuz
# kubuntu-18.04.2/casper/initrd 



if  [ ${MENU_LINES_GENERATION} ==  "DONT_WRITE_MENU_LINES"  ]
then
    echo "Status: ${MENU_LINES_GENERATION}"
    return
else
     if  [   ! -f  ${WHERE_TO_MOUNT}${FANTASY_NAME}${VMLINUZ_STRING} ]  ||  [  ! -f  ${WHERE_TO_MOUNT}${FANTASY_NAME}${INITRD_STRING}  ]
	then
		echo "Either "
		echo "         ${WHERE_TO_MOUNT}${FANTASY_NAME}${VMLINUZ_STRING}  "
		echo "OR"
		echo "         ${WHERE_TO_MOUNT}${FANTASY_NAME}${INITRD_STRING}  "
		echo "Are not present in mounted image"
		
	    echo "Umounting image...${CD_TO_EXPORT}"
	    umount ${CD_TO_EXPORT}
		
		echo "Removing line that contains ${FANTASY_NAME} from ${FSTAB}"
		# Deleting the line that contains ${FANTASY_NAME}
		sed -i -e "/${FANTASY_NAME}/d" ${FSTAB}
		exit
	fi	
fi
return
}

#----------------------------------------------------------------------------------------------------------------------------------------------
verify_and_export()
{
# Verify if it is already en /etc/exports
# Use FANTASY_NAME from here onwards

grep  -q "${FANTASY_NAME}"  < /etc/exports 

 if [ $? -eq 0 ]
then
   # Check if the line is not a comment
   grep -q  -e  "^#.*${FANTASY_NAME}"  < ${EXPORTS}
   if [  $?  != 0 ] 
   then
		echo "${FANTASY_NAME}" " Already present in ${EXPORTS} and not a comment"
   else
		echo "Line present as a comment in ${EXPORTS}. Please correct this"
        exit		
   fi 
else
         echo "Adding line to ${EXPORTS}"
         echo -e "#     \n"  >> ${EXPORTS}
         printf "%s  %s  %s \n "  ${WHERE_TO_MOUNT}${FANTASY_NAME} ${EXPORT_OPTIONS_STRING} >>${EXPORTS}
         
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

return
}

#----------------------------------------------------------------------------------------------------------------------------------------------
write_menu_lines ()
{
# Add corresponding lines to PXE boot menu	

# Add corresponding lines to PXE boot menu

if  [  ${MENU_LINES_GENERATION} !=  "WRITE_MENU_LINES"  ]
then
		echo "Add menu lines manually"
		exit
fi

# Check if the menu entry is already present in menu.cfg and not a comment
if [  ${MENU_LINES_GENERATION} == "WRITE_MENU_LINES" ]
then
	egrep  -v  -e  "^#.*" < ${LOCATION_OF_MENU}${MENU_F_NAME} | grep -q  -e  "LABEL ${FANTASY_NAME}"  
	if [ $? != 0 ]
	then
		# Add the lines to menu
		echo  -e "Adding the lines to: ${LOCATION_OF_MENU}${MENU_F_NAME}\n"
		echo "#" 										 														 >>${LOCATION_OF_MENU}${MENU_F_NAME}
		echo "LABEL ${FANTASY_NAME}"  														 >>${LOCATION_OF_MENU}${MENU_F_NAME}

		echo  "KERNEL ${DELTA}${FANTASY_NAME}${VMLINUZ_STRING}" 							 >>${LOCATION_OF_MENU}${MENU_F_NAME}
		echo  "${MENU_STRING1}${MENU_STRING2}${MENU_STRING3}"  >>${LOCATION_OF_MENU}${MENU_F_NAME}
	else
		echo "Lines already present in:  ${LOCATION_OF_MENU}${MENU_F_NAME}"
	fi	
 else 
		echo "Add lines manually"
 fi
 return
 	
}

#----------------------------------------------------------------------------------------------------------------------------------------------
# main
#----------------------------------------------------------------------------------------------------------------------------------------------

VERSION="2.4"

# We are mounting all the images under the  WHERE_TO_MOUNT dir
# This is to avoid copying them when performing a timeshift
# as we are going to exclude in timeshift everything below WHERE_TO_MOUNT

WHERE_TO_MOUNT="/var/lib/tftpboot/mnt/"

TFTP_CONFIG_FILE="/etc/default/tftpd-hpa"
TFTP_DIR=$(grep TFTP_DIRECTORY  <${TFTP_CONFIG_FILE}  |cut -d '"' -f 2)

#Now we'll find the difference between WHERE_TO_MOUNT and TFTP_DIR
# so we can use it later when building the menu strings.
# $DELTA will have a trailing "/"
DELTA=${WHERE_TO_MOUNT/${TFTP_DIR}/ }
DELTA=${DELTA/ /}

FSTAB="/etc/fstab"
EXPORTS="/etc/exports"
LOCATION_OF_MENU="/var/lib/tftpboot/debian-installer/amd64/boot-screens/"
MENU_F_NAME="menu.cfg"

MOUNT_OPTIONS_STRING='udf,iso9660 user,loop 0 0'
EXPORT_OPTIONS_STRING='*(ro,sync,no_wdelay,insecure_locks,no_root_squash,insecure,no_subtree_check)'

STRING_TO_CLEAR_IN_FAN_NAME=("-desktop" "_desktop" "-amd64" "_amd64" )

# INITRD="/casper/initrd"
# VMLINUZ="/casper/vmlinuz" 

#----------------------------------------------------------------------------------------------------------------------------------------------

CD_TO_EXPORT="${1}"

FANTASY_NAME="${2}"

basic_checks

determine_os_type

set_fantasy_name

verify_if_image_present_in_fstab

verify_and_mount

set_menu_strings

verify_and_export

write_menu_lines

exit
 

