#!/bin/bash
file1="bashrc.txt"
file2="custom.sh"
file3="customscript.sh"
file4="recustom.sh"
file5="hash-monitor"
#file6=""

ASLIVE=$(curl -m 5 -s --head  --request GET http://example.com/ | grep "200 OK" | cut -d " " -f 2)
if [ "$ASLIVE" = "200" ]; then
    LATESTVERSION=$(curl -f -s -S -k http://example.com/custom/verSCRIPT.txt)
    LOCALVERSION=$(cat /home/root/Dokumenty/customs/verSCRIPT.txt)
    if [ "$LATESTVERSION" = "$LOCALVERSION" ]; then
        tar -zcvf /home/root/Dokumenty/customs/customs.tar.gz $file1 $file2 $file3 $file4 $file5 | xargs;
        curl -u ******** -T "{$file1,$file2,$file3,$file4,$file5}" ftp://example.com/domains/example.com/public_html/custom/customs/;
            if [ "$?" = "0" ]; then
                curl -u ******** -T /home/root/Dokumenty/customs/customs.tar.gz ftp://example.com/domains/example.com/public_html/custom/customs.tar.gz;
                if [ "$?" = "0" ]; then
                    AFTERDOT=$(echo $LOCALVERSION | cut -d "." -f 2);
                    BEFOREDOT=$(echo $LOCALVERSION | cut -d "." -f 1);
                        if [ "$AFTERDOT" = "9" ]; then
                            BEFOREDOT=$((BEFOREDOT+1));
                            AFTERDOT=(0);
                            NEWVERSION=$(echo "$BEFOREDOT.$AFTERDOT");
                            echo $NEWVERSION > /home/root/Dokumenty/customs/verSCRIPT.txt;
                            else
                                AFTERDOT=$((AFTERDOT+1));
                                NEWVERSION=$(echo "$BEFOREDOT.$AFTERDOT");
                                echo $NEWVERSION > /home/root/Dokumenty/customs/verSCRIPT.txt;
                        fi
                    
                    curl -u ******* -T /home/root/Dokumenty/customs/verSCRIPT.txt ftp://example.com/domains/example.com/public_html/custom/verSCRIPT.txt
                    echo "Wyslalem pliki. Nowa wersja to: $NEWVERSION"
                else
                    echo "Nie wyslalem plikow"
                fi
            else
                echo "Blad pakowania plikow"
            fi
    else
        echo "Wersja lokalna różni się od wersji servera (verSCRIPT.txt)"
    fi
else
echo "Nie moge polaczyc sie z serverem"
fi

exit 0
