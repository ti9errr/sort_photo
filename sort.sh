#!/bin/bash

EXIF_BIN=/volume2/share/sys/photo/exiftool/bin

jfdi()
{

    SOURCEDIR=$1
    DESTDIR=$2                                                                                         
    
    eadir=$SOURCEDIR/'@eaDir'
    rm -r $eadir
    
    MAXDEPTH='-maxdepth 1' #Search only in directory

	# Enable handling of filenames with spaces:
	SAVEIFS=$IFS

  	for FILE in $(find $SOURCEDIR $MAXDEPTH -not -wholename "*._*" -iname "*.JPG" -or -iname "*.JPEG" -or -iname "*AVI" -or -iname "*MOV" -or -iname "*MP4" -or -iname "*PNG") 
	do
		INPUT=${FILE}
		DATE=($($EXIF_BIN/exiftool -CreateDate -FileModifyDate -DateTimeOriginal "$INPUT" | awk -F: '{ print $2 ":" $3 ":" $4 ":" $5 ":" $6 }' | sed 's/+[0-9]*//' | sort | grep -v 1970: | cut -d: -f1-6 | tr ':' ' ' | head -1) )
	    
    	if [ ! -z "$DATE" ] 
		then
	    	YEAR=${DATE[0]}
    		MONTH=${DATE[1]}

			if [ "$DATE" == "null" ]
			then
    	    	DATE=($($EXIF_BIN/exiftool -CreateDate -FileModifyDate -MediaCreateDate "$INPUT" | awk -F: '{ print $2 ":" $3 ":" $4 ":" $5 ":" $6 }' | sed 's/+[0-9]*//' | sort | grep -v 1970: | cut -d: -f1-6 | tr ':' ' ' | head -1) )
      		fi
	
	    	if [ -z "$DATE" ] || [ "$DATE" == "null" ] # If exif extraction failed
    		then
	    		DATE=$(stat -f "%Sm" -t %F "${INPUT}" | awk '{print $1}'| sed 's/-/:/g')
			fi
		
    		if [ "$YEAR" -gt 0 ] & [ "$MONTH" -gt 0 ]
    		then  	
				OUTPUT_DIRECTORY=${DESTDIR}/${YEAR}/${YEAR}${MONTH}
		    	
				mkdir -pv ${OUTPUT_DIRECTORY}

				OUTPUT=${OUTPUT_DIRECTORY}/$(basename ${INPUT})

				if [ -e "$OUTPUT" ] && ! cmp -s "$INPUT" "$OUTPUT"
				then
					echo "WARNING: '$OUTPUT' exists already and is different from '$INPUT'."
				else
					#echo "Moving '$INPUT' to $OUTPUT"
					rsync -ah --progress "$INPUT" "$OUTPUT"

					if ! cmp -s "$INPUT" "$OUTPUT"
					then
  						echo "WARNING: copying failed somehow, will not delete original '$INPUT'"
	  				else
 		  				rm -f "$INPUT"
			  		fi

				fi

			else
  				echo "WARNING: '$INPUT' doesn't contain date."
			fi

		else
			echo "WARNING: '$INPUT' doesn't contain date."
		fi

	done	

	# restore $IFS
	IFS=$SAVEIFS
}

jfdi /volume2/photo/ttl/inbox /volume2/photo/ttl/photo                                                                                         

jfdi /volume2/photo/aud/inbox /volume2/photo/aud/photo

# jfdi /volume2/photo/wwz/inbox /volume2/photo/wwz/photo


