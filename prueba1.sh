#! /bin/bash

# Prueba

RUN_STR=$0
SUPPORT_MATRIX_DIR="Support_Matrix"


SCR_NAME=${RUN_STR##*/} # Elimina path name
PATH_NAME=${RUN_STR%/*}  # Elimina file name

if [ ${SCR_NAME} == ${PATH_NAME} ]
then
PATH_NAME="."
fi

echo $RUN_STR
echo   $SCR_NAME 
echo  $PATH_NAME 

echo " "

# NOM_DIR_SHORT=${Lista_files_index[${indice_hash}]%/*}  
# NOM_DIR_SHORT=${NOM_DIR_SHORT##*/} # 
echo ${PATH_NAME}/${SUPPORT_MATRIX_DIR}

#find "${PATH_NAME}/${SUPPORT_MATRIX_DIR}"  -name '*.sh' -type f 
#echo " "

LISTA_FILES=$(find "${PATH_NAME}/${SUPPORT_MATRIX_DIR}"  -name '*.sh' -type f | sed  "s/.*${SUPPORT_MATRIX_DIR}\///g  " )

# LISTA_FILES=$(find ${PATH_NAME}/Support_Matrix -name '*.sh' -type f | sed 's/.*Support_Matrix\///g ' )


echo $LISTA_FILES



for I in ${LISTA_FILES}
do
	SUPPORT_STAT=${I%/*}
	SUPPORT_STAT=${SUPPORT_STAT^^}
	OS=${I##*/}     # Delete everything preceeding "/"
	OS=${OS%%.*} # Delete ".sh"  that is everything after OS name...
	
	echo ${SUPPORT_STAT} ${OS}
done

