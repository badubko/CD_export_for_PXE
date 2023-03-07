#!  /bin/bash


# Usage:


show_usage ()
{
	echo  -e  "\nUSAGE: $0  cd_to_UNexport   \n"
	cat <<!FINIS
    Version:  $VERSION
    This script will UNDo all the operations added by cd_export.sh needed to enable PXE boot from an
    iso image of a bootable linux cd,  passed as the first argument.
    
    First argument "cd_to_UNexport" can be either:
    
    - Complete path and file name of the mounted iso image:
		/samba/public-q/Linux/Ubuntu/ubuntu-mate-22.04.1-desktop-amd64.iso
     
     - Fantasy name used to mount the image  that was supplied by the user:
			ubuntu_mate_22
       or obtained from the iso name, if a fantasy_name was not supplied as a second argument to the cd_export script. 
       In this case it would be:
			ubuntu-mate-22.04.1
			
        1- Removes the corresponding lines from PXE boot menu (if there are any)
			${LOCATION_OF_MENU}${MENU_F_NAME}
    	2- delete_line_from_exports
		3- unexport
		4- umount_cd
		5- delete_line_from_fstab
		6- delete_mount_point
        
    Limitations:    
    In this version, the functionaliy of this scipt is limited only to bootable linux images.

!FINIS
return
}

delete_line_from_fstab ()
{
	sed -i  -r -e   "/${MOUNT_NAME_FSTAB}/d"  "${FSTAB}" 
	echo "Line containing ${MOUNT_NAME_FSTAB} deleted from ${FSTAB}"
	return
}

umount_cd ()
{
    umount ${CD_TO_UN_EXPORT}
    echo "Umounted ${CD_TO_UN_EXPORT}"
    return
}

unexport ()
{
	exportfs -r
	
	echo "Unexported:  " "${WHERE_TO_MOUNT}${MOUNT_NAME_FSTAB}"
	return
}

delete_line_from_exports ()
{
	# As ${WHERE_TO_MOUNT} contains multiple "/"
	# the "/" character is replaced by "|" as pattern delimiter, but should be escaped with "\ "at the beggining.
	# sed -i  -r  -e  "\|${WHERE_TO_MOUNT}${MOUNT_NAME_FSTAB}|d"  "${EXPORTS}" 
	
	sed -i  -r  -e  "\|${MOUNT_NAME_FSTAB}|d"  "${EXPORTS}" 
	
	echo "		Line containing "
	echo "				${WHERE_TO_MOUNT}${MOUNT_NAME_FSTAB}"
	echo "		was deleted from ${EXPORTS}"
	
	return
}
	
delete_line_from_menu ()
{
	#Just in case: Find which FANTASY name was used in menu...
	
	# This will delete comment and no-comment lines containing pattern and +2 lines
	# The sequence is
	# LABEL
	# KERNEL
	# APPEND
	
	# This should be refined to cover all alternatives, ie, comment lines in the middle...
	
	# for NAME in  ${MOUNT_NAME_FSTAB} ${MOUNT_NAME}     
	sed -i  -r  -e "/${MOUNT_NAME_FSTAB}/,+2d"  "${LOCATION_OF_MENU}${MENU_F_NAME}" 

	return
}

delete_mount_point()
{
	rmdir  "${WHERE_TO_MOUNT}${MOUNT_NAME_FSTAB}"
	if [ $? ]
	then
		echo "Mount point  ${WHERE_TO_MOUNT}${MOUNT_NAME_FSTAB} was removed"
	else
	    echo "Error:  ${WHERE_TO_MOUNT}${MOUNT_NAME_FSTAB} was NOT removed"
	fi    
	return
}

#----------------------------------------------------------------------------------------------------------------------------------------------
# main
#----------------------------------------------------------------------------------------------------------------------------------------------

VERSION="2.0"
WHERE_TO_MOUNT="/var/lib/tftpboot/mnt/"
FSTAB="/etc/fstab"
EXPORTS="/etc/exports"
LOCATION_OF_MENU="/var/lib/tftpboot/debian-installer/amd64/boot-screens/"
MENU_F_NAME="menu.cfg"

MOUNT_OPTIONS_STRING='udf,iso9660 user,loop 0 0'
EXPORT_OPTIONS_STRING='*(ro,sync,no_wdelay,insecure_locks,no_root_squash,insecure,no_subtree_check)'

STRING_TO_CLEAR_IN_FAN_NAME=("-desktop" "_desktop" "-amd64" "_amd64" )


#----------------------------------------------------------------------------------------------------------------------------------------------
if [ ${USER} != "root" ]
then
	echo "Must be root to run this script"
	exit
fi

if [ $# -eq 0 ]
then
	show_usage
	exit
fi	

CD_TO_UN_EXPORT="${1}"



# Check if cd is mounted and get mount_point  from mount
# Get FANTASY_NAME === name used to mount the CD
# Check if present in fstab with the same name

mount | grep   -q  "${CD_TO_UN_EXPORT}" 
 
 if [ $? -eq 0 ]
then
   echo "${CD_TO_UN_EXPORT}" " is mounted..."
   MOUNT_STATUS="MOUNTED"
   # Determine  name used to mount
	MOUNT_NAME=$( mount | grep   "${CD_TO_UN_EXPORT}" | sed  -r -e 's/ +/ /g' | cut -d " " -f 3 )
	MOUNT_NAME=${MOUNT_NAME##*/}
	
	echo " Mount name: ${MOUNT_NAME}"
	
else
    echo "${CD_TO_UN_EXPORT}" " is NOT mounted..."
	MOUNT_STATUS="NOT_MOUNTED"
fi
 
# From fstab: 
# Select all non comment lines | Select lines containing CD_TO_UN_EXPORT | subsitute spaces by only one space
LINE_IN_FSTAB=$( grep  -E -v  -e  "^#.*" < ${FSTAB} | egrep  -E -e  "${CD_TO_UN_EXPORT}" | sed  -r -e 's/ +/ /g')
	
if [[ -z ${LINE_IN_FSTAB} ]] 
then
		echo "${CD_TO_UN_EXPORT} not present in ${FSTAB}"
		echo "unmount manually"
		FSTAB_STATUS="NOT_IN_FSTAB"     
		
else
	MOUNT_NAME_FSTAB=$( cut -d " " -f 2 <<<${LINE_IN_FSTAB}  )
   	MOUNT_NAME_FSTAB=${MOUNT_NAME_FSTAB##*/}	

	echo " Mount name in ${FSTAB}:  ${MOUNT_NAME_FSTAB}"
		
	if  [ ${MOUNT_STATUS} == "MOUNTED"  ]  &&  [ "${MOUNT_NAME_FSTAB}" != "${MOUNT_NAME}" ]
	then
			
			FSTAB_STATUS="NAMES_DIFFER"     
		        
	else
			FSTAB_STATUS="IN_FSTAB" 	        
	fi 

fi

echo "Status:   ${MOUNT_STATUS}_${FSTAB_STATUS}"

case  "${MOUNT_STATUS}_${FSTAB_STATUS}"  in
NOT_MOUNTED_NOT_IN_FSTAB )
		echo "Nothing to do here..."
		exit
		;;
NOT_MOUNTED_IN_FSTAB )
		delete_line_from_menu
		delete_line_from_exports
		delete_line_from_fstab
		;;
MOUNTED_IN_FSTAB )
		delete_line_from_menu
		delete_line_from_exports
		unexport
		umount_cd
		delete_line_from_fstab
		delete_mount_point
		;;
MOUNTED_NOT_IN_FSTAB )		
		delete_line_from_menu
		# Improve this temporary fix...
		# We don't have an entry in  fstab, so we use the mount point name we have got from the mount command.
		MOUNT_NAME_FSTAB="${MOUNT_NAME}"
		delete_line_from_exports
		unexport
		umount_cd
		delete_mount_point
		;;
MOUNTED_NAMES_DIFFER)		
		echo "${MOUNT_NAME_FSTAB}" "   "  "${MOUNT_NAME}" 
		echo "Mount name  is not the same as mount point in ${FSTAB} Fix this manually..."
		exit
		;;		
* )
		echo "What is this Macaya? ${MOUNT_STATUS}_${FSTAB_STATUS}"
		;;
esac

# Delete lines from menu using FANTASY_NAME

# Check if cd present in exports using FANTASY_NAME

# Check if cd is exported  using FANTASY_NAME

#  Delete entry from exports and "unexport" by updating 

# Umount cd

# Delete from fstab


