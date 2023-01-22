#!  /bin/bash


# Usage:
# cd_export  cd_to_export    [fantasy_name_to_mount]

VERSION="1.0"
WHERE_TO_MOUNT="/var/lib/tftpboot/"
FSTAB="/etc/fstab"
EXPORTS="/etc/exports"

MOUNT_OPTIONS_STRING='udf,iso9660 user,loop 0 0'
EXPORT_OPTIONS_STRING='*(ro,sync,no_wdelay,insecure_locks,no_root_squash,insecure,no_subtree_check)'

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
   
#     echo "${CD_TO_EXPORT}"
   FANTASY_NAME=${CD_TO_EXPORT##*/}

   FANTASY_NAME=${FANTASY_NAME%.*}
   echo "Fantasy Name: " $FANTASY_NAME
   
fi

# Check if this image is already present in /etc/fstab

grep  -q "${CD_TO_EXPORT}"  < /etc/fstab 

 if [ $? -eq 0 ]
then
   # Check if the line is not a comment
   egrep  -e  "^#.*${CD_TO_EXPORT}"  < /etc/fstab
   if [  $?  != 0 ] 
   then
		echo "${CD_TO_EXPORT}" " Already present in fstab and not a comment"
		# Check if FANTASY_NAME is the same as in fstab...
		
		# --->>> COmpletar aqui ....
 
   else
		echo "Line present as a comment. in /etc/fstab Please correct this"
        exit		
   fi 
else
        echo "Adding line to fstab"
        echo -e "#     \n"  >>/etc/fstab
        printf "%s  %s  %s \n "  ${CD_TO_EXPORT}  ${WHERE_TO_MOUNT}${FANTASY_NAME} ${MOUNT_OPTIONS_STRING} >>/etc/fstab
fi
# 
# Verify if it's already mounted

mount | grep   "${CD_TO_EXPORT}" 
 
 if [ $? -eq 0 ]
then
   echo "${CD_TO_EXPORT}" " Already mounted..."
   # Determine Fastasy name used to mount
	MOUNT_NAME=$( mount | grep   "${CD_TO_EXPORT}" | cut -d " " -f 3 )
	MOUNT_NAME=${MOUNT_NAME##*/}
	echo $MOUNT_NAME
else
   echo "Mount it!"  
   # FInd if target directory exists
   if [  ! -d ${WHERE_TO_MOUNT}${FANTASY_NAME} ]
   then
		mkdir ${WHERE_TO_MOUNT}${FANTASY_NAME}
		if  [ $? -eq 0 ]
		then
			echo "Target directory creation failed:  ${WHERE_TO_MOUNT}${FANTASY_NAME}" 
			exit
		fi	
	fi		
   mount --source  ${CD_TO_EXPORT} 
    
fi

# Verify if it is already en /etc/exports
# Use FANTASY_NAME from here onwards

grep  -q "${FANTASY_NAME}"  < /etc/exports 

 if [ $? -eq 0 ]
then
   # Check if the line is not a comment
   egrep  -e  "^#.*${FANTASY_NAME}"  < /etc/exports
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
   exit
 else
   echo "Exporting"  
   exportfs -a
fi

