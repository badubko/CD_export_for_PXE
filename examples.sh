Lista_files=$(find $(echo ${TARGET_DIRS[$NUM_REPOS]}) -type f | grep -v ${PATRON_DIR_MINIAT_CGATE} | sort )

    Tfind=$(date +%s)
#   echo ${Tfind} 
	date "+%F %T"
 	echo "Tiempo find: " $((Tfind-T0))	

#for full_path_name in ${Lista_files[@]}
#do

  nom_file=${full_path_name##*/}
  
  
  LISTA_FILES=$(find  $DIR_FILES_COPIADOS_DEL_CEL/ -type f | grep -v "$PATRON_DIR_MINIAT_CGATE" | sort)
  
  LISTA_FILES=$(find  Supported/ -type f |  sort)
  
  
  LISTA_FILES=$(find  Supported/ -type f | sed -e 's/Supported\///' )

LISTA_FILES=${LISTA_FILES/Supported\//}

LISTA_FILES=$(find  Supported/ -type f ) ; LISTA_FILES=${LISTA_FILES//Supported\//} ; LISTA_FILES=${LISTA_FILES%%.*}

LISTA_FILES=$(find  Supported/ -type f ) ; LISTA_FILES=${LISTA_FILES//Supported\//} ; LISTA_FILES=${LISTA_FILES//.sh/}


grep -q "mint" <<<$LISTA_FILES ; echo $?



LISTA_FILES=$(find  Support_Matrix/ -type f ) ; LISTA_FILES=${LISTA_FILES//Support_Matrix\//} ; LISTA_FILES=${LISTA_FILES//.sh/}

 LISTA_FILES=$(find  ./Support_Matrix/ -type f ) ; LISTA_FILES=${LISTA_FILES//Support_Matrix\//} 
 LISTA_FILES=${LISTA_FILES//.sh/}; LISTA_FILES=${LISTA_FILES//.\//}
$ echo $LISTA_FILES
