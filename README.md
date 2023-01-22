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
