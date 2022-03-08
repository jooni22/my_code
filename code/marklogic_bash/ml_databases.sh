#!/usr/bin/bash

##### bash -x <-- Debug bash
# -i    interactive     Script runs in interactive mode.
# -n    noexec  Read commands, but don't execute them (syntax check).
# -x    xtrace  Print each command and its expanded arguments to stderr before executing it.

env=$(exec /home/users/stankiem/mlms-shell/.env_var);
env2=$(echo $env | base64 -d | base64 -d)
env3=$(echo $env2 | tr -t "s" "S")
DB_getName=$(curl -s --anyauth --user stankiem:$env3 -i -X GET -H "Content-Type: application/xml" https://example.com:8002/manage/v2/databases > DB_name); # download db
LOC_date=$(date +"%x %X" | tr -t " " "_" | tr -t "/" "_" | tr -t ":" "_")
FILE_older=$(find . -name DB_name -mmin +0 | wc -l)
DB_qty=$(grep 'list-count units="quantity"' DB_name | cut -d ">" -f2 | cut -d "<" -f1); # count of db
DB_uri=$(grep uriref DB_name | cut -d ">" -f2 | cut -d "<" -f1);
DB_refname=$(grep nameref DB_name | cut -d ">" -f2 | cut -d "<" -f1);
DB_curl=('curl -s --anyauth --user stankiem:'$env3' -i -X GET https://example.com:8002')

###< check DB_satus exist
if [ ! -e DB_status ]; then
    mkdir DB_status;
fi;

if [ ! -e DB_history ]; then
    mkdir DB_history;
fi;
###>

if [ $FILE_older -eq 1 ]; then
###<< fetch data
  for n in $DB_uri
  do
    TEMP_db_name=$(echo $n | cut -d "/" -f5);
    $DB_curl$n'?view=status&format=xml' > DB_status/$TEMP_db_name
    if [ $? -ne 0 ]; then
      echo $TEMP_db_name"[bad]";
    else
      echo $TEMP_db_name"[ok]";
    fi
  done
###>>
fi
###< print
  for n in $DB_refname
  do
    DB_data_size=$(grep "/data-size" DB_status/$n)
    DB_unit=$(echo $DB_data_size | cut -d '"' -f2 | cut -d '"' -f1)
    DB_size_val=$(echo $DB_data_size | cut -d ">" -f2 | cut -d "<" -f1)
    if [ ! -e DB_history/$n ]; then
        touch DB_history/$n
        echo $LOC_date > DB_history/$n
        echo $DB_size_val >> DB_history/$n
    fi
    ED_var_date=$(ed -s DB_history/$n <<< 1);
    ED_var_size=$(ed -s DB_history/$n <<< 2);
    echo $ED_var_date" "$LOC_date > DB_history/$n;
    echo $ED_var_size" "$DB_size_val >> DB_history/$n;
  done
