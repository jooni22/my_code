#!/bin/bash

NOW=$(date +"%m-%d-%Y_%T")

echo "Refresh data to Gsheet"
echo "Status of execution is in log.txt"
echo "Starting..."
#-----------------------------------------------#
############### Get config variables 
#-----------------------------------------------#
CFG_FILE=config.cfg
if [ -f "$CFG_FILE" ]; then
    source <(cat config.cfg | grep -v '^\[')
    if [ -z "$mlPassPath" ]; then
        echo "Sourcing config.cfg"
    else
        check_mlPass=$(cat $mlPassPath)
        eval $check_mlPass
    fi
else
    echo $NOW" STATUS: Missing config.cfg" >> log.txt
    echo "Missing config.cfg"
fi
#-----------------------------------------------#
############### Check if jq binary exist
#-----------------------------------------------#
CHECK_JQ_PATH=$(which jq > /dev/null 2>&1)
if [ $? -eq 0 ]; then
    JQ_PATH=$(which jq)
    echo "Binary of jq found"
else
    FIND_JQ_BINARY=$(find . -name "jq" | head -n1)
    if [ $? -eq 0 ]; then
        JQ_PATH=$FIND_JQ_BINARY
        echo "Binary of jq exist in "$JQ_PATH
    else
        echo $NOW" STATUS: Can't find jq binary." >> log.txt
        echo "Can't find jq binary. You can download from: https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64"
    fi
fi
#-----------------------------------------------#
############## Check python version #############
#-----------------------------------------------#
CHECK_PY_PATH=$(python -c 'import platform; print(platform.python_version())' | grep "3")
if [ $? -eq 0 ]; then
    PY_PATH=$(which python)
    echo "Python 3 found"
else
    FIND_PYTHON3=$(find /opt/rh -name "python" | grep "bin")
    if [ $? -eq 0 ]; then
        PY_PATH=$FIND_PYTHON3
        echo "Python 3 found as scl software"
    else
        echo $NOW" STATUS: Can't find Python3." >> log.txt
        echo "You have to install python3 and pip. Then from pip install google-api-python-client google-auth-httplib2 google-auth-oauthlib gspread oauth2client pandas"
    fi
fi
#-----------------------------------------------#
############# Gather data from ML ###############
#-----------------------------------------------#
echo "Collecting data from MarkLogic to res/dashboard.json"
GET_JSON_DATA=$(curl --user $mlUser:$mlPass -o res/dashboard.json -sS -X POST --data-binary @src/study-dashboard.xqy -H "Content-type: application/x-www-form-urlencoded" -H "Accept: multipart/mixed; boundary=BOUNDARY" https://$mlServerHostname:$mlPort/LATEST/eval)
#-----------------------------------------------#
#### Prepare CSV files and update to GSHEET #####
#-----------------------------------------------#
FILE=res/dashboard.json

if [ -f "$FILE" ]; then
    CHECK_JSON_DATA=$(grep "requestTime" res/dashboard.json)
        if [ $? -eq 0 ]; then
            echo $CHECK_JSON_DATA > res/dashboard.json
            STUDIES_EXTRACT=$($JQ_PATH -r '. | .studies.items' res/dashboard.json > res/studies.json)
            sed -i 's/"studyName"/"Study Number"/g; s/"ds"/"Rave URL"/g; s/"ingestion"/"Ingestion Adverse"/g; s/"aer"/"Event Reporting"/g; s/"scv"/"Study Clinical View"/g; s/"sov"/"Study Operational View"/g' res/studies.json
            STUDIES_SUMMARY_EXTRACT=$($JQ_PATH -r '. | {"No. of studies ingested (CRF data) from Rave": ."ingestedStudies", "No. of studies active in Adverse Event Reporting": ."aerStudies", "No. of studies active in Study Clinical View": ."scvStudies", "No. of studies active in Study Operational View": ."sovStudies"}' res/dashboard.json > res/studies_sumary.json)
            echo "Running python script"
            $PY_PATH src/sheet_update.py
            if [ $? -eq 0 ]; then
                echo $NOW" STATUS: Success" >> log.txt
            else
                echo $NOW" STATUS: Fail with python script execution" >> log.txt
            fi
        else
            JSON_DATA_ERROR=$(cat res/dashboard.json)
            echo $NOW" STATUS: Fail with gather data from MarkLogic to dashborad.json file. HTTP HEADER: "$JSON_DATA_ERROR >> log.txt
            #TODO: MAIL IF FAIL
        fi
else
    echo $NOW" STATUS: File dashborad.json not exist and can't gather data from curl." >> log.txt
fi
echo "Refresh data done, check log.txt for more info."
#-----------------------------------------------#
###################### END ######################
#-----------------------------------------------#
