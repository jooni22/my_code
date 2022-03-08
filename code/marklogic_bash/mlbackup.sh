#!/bin/bash

BASE="/var/opt/MarkLogicBackup"
PROJECTS=$(ls $BASE)
TODAYDATE=$(date +%Y%m%d)
YEAR=$(date +%Y)
#DB7D=()
#DB14D=()
#GLO_AVE_DURATION=()
#GLO_MAX_DURATION=()
#GLO_RESULT=()

echo -e "Projects:\e[91m"$PROJECTS"\e[0m"
echo "Type project name folders"
read FOLDERS;
for NAME in $FOLDERS
do
    echo -e "\e[32m-------------- "$NAME" --------------\e[0m"
    DATABASES=$(ls $BASE/$NAME/ | xargs)

    for DBNAME in $DATABASES # loop for all dirs
    do
		ALLBACKUPS=$(find $BASE/$NAME/$DBNAME/ -maxdepth 1 -type d -name $YEAR'*' -exec basename {} \;) #### with pwd
		AVERAGE=() 
		LASTBACKUP=$(echo $ALLBACKUPS | awk 'NF>1{print $NF}')
        LASTDATE=$(echo $LASTBACKUP | sed 's/-.*//')
        DAYSAGO=$(echo $((($(date +%s)-$(date +%s --date "$LASTDATE"))/(3600*24))))
		if [ "$DAYSAGO" -gt 14 ]; then
                DDAGO=$(echo -e "LastBackup" $LASTDATE "-\e[91m" $DAYSAGO "Days ago\e[0m")
				DB14D+=($DBNAME)
        elif [ "$DAYSAGO" -gt 7 ]; then
                DDAGO=$(echo -e "LastBackup" $LASTDATE "-\e[93m" $DAYSAGO "Days ago\e[0m")
				DB7D+=($DBNAME)
        else
                DDAGO=$(echo -e "LastBackup" $LASTDATE "-" $DAYSAGO "Days ago")
        fi
		for BACKUPS in $ALLBACKUPS #### print backuptag
		do
			
			BACKUPTAG=$BASE/$NAME/$DBNAME/$BACKUPS/BackupTag.txt
			
			##-> if exist read start time
			if [ -f "$BACKUPTAG" ]; then 
				STARTED=$(cat $BACKUPTAG | grep "Started" | cut -d " " -f 2)
				COMPLETED=$(cat $BACKUPTAG | grep "Completed" | cut -d " " -f 2)
				STARTEDTIMESTAMP=$(date --date=$STARTED +"%s")
				COMPLETEDTIMESTAMP=$(date --date=$COMPLETED +"%s")
				PROCESSTIME=$(expr $COMPLETEDTIMESTAMP - $STARTEDTIMESTAMP)
				DURATION=$(date -d@$PROCESSTIME -u +%H'h '%M'm '%S's')
				echo $BACKUPS' | Duration: '$DURATION 
				AVERAGE+=($PROCESSTIME) 
			else
				echo $BACKUPS' | Duration: -'
			fi
		done
		
		if [ -n "$AVERAGE" ]; then ## if backup_time exist count time
			TOTAL=0
			for n in ${AVERAGE[@]}
			do
				(( TOTAL += n ))
			done
			AVETIME=$(expr $TOTAL / ${#AVERAGE[@]})
			MAXTIME=$(echo ${AVERAGE[*]} | tr ' ' '\n' | sort -nr | head -n1) 
			GLO_AVE_DURATION+=$(date -d@$AVETIME -u +%H:%M:%S)
			GLO_MAX_DURATION+=$(date -d@$MAXTIME -u +%H:%M:%S)
			GLO_RESULT+=$(echo $DBNAME';'$GLO_AVE_DURATION';'$GLO_MAX_DURATION' ') 

			AVEDURATION=$(date -d@$AVETIME -u +%H'h '%M'm '%S's')
			echo -e '\e[93m'$DBNAME' | Average duration: '$AVEDURATION' | \e[0m'$DDAGO
		else
			echo -e '\e[93m'$DBNAME' | Average duration: - | \e[0m'$DDAGO
		fi
		echo "----------"
		GLO_AVE_DURATION=() 
		GLO_MAX_DURATION=()
    done
done
echo -e '\e[93m''--- More than 7 days ---'
echo "${DB7D[@]}" | tr ' ' '\n'

echo -e '\e[91m''--- More than 14 days ---'
echo "${DB14D[@]}" | tr ' ' '\n'

echo -e '\e[0m''--- DB name; Average duration; Max duration ---'
echo "${GLO_RESULT[@]}" | tr ' ' '\n'
#printf ' %s\n' "${GLO_AVE_DURATION[@]}"
