    Version:  $VERSION
    Provided that bootp, tftp and nfs server are set on the PXE boot server,
    this script will do all the operations needed to enable PXE boot from an
    iso image of a bootable linux cd,  passed as the first argument.
    
    1- After performing various checks, it will add it to /etc/fstab
    using as the mount point a  "Fantasy Name" either passed as a second argument 
    or created from the name of the iso image.
    If the iso image is not  already mounted, it is mounted.
    
    2- After performing various checks, the mount point is added to /etc/exports and exported.
         
    3- Finally, it will add the corresponding lines to PXE boot menu defined by the variables
        ${LOCATION_OF_MENU}${MENU_F_NAME}
        
    Limitations:    
    In this version, the functionaliy of this scipt is limited only to bootable linux images.
