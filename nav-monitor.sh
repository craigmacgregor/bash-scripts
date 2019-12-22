#!/usr/bin/env bash

echo $(date -u) "Running Network Monitor"

VERSION="4.7.2"
USER="<linux username>"
TOLERANCE=2
NOW=`date +"%s"`

echo "NOW" $NOW

BLOCKCOUNT=`/home/$USER/navcoin-$VERSION/bin/navcoin-cli getblockcount`
BLOCKHASH=`/home/$USER/navcoin-$VERSION/bin/navcoin-cli getblockhash $BLOCKCOUNT`

echo "BLOCKCOUNT" $BLOCKCOUNT
echo "BLOCKHASH" $BLOCKHASH

NAVEXURL="https://api.navexplorer.com/api/block/$BLOCKCOUNT"

NXTRIES=0
while [ "$NXTRIES" -lt 5 ]; do
        NAVEXDATA=`curl -s $NAVEXURL`
        NAVEXBLOCKHASH=`echo $NAVEXDATA | jq -r '.hash'`
        echo "NAVEXBLOCKHASH" $NAVEXBLOCKHASH
        if [ "$NAVEXBLOCKHASH" == "null" ]; then
                NXTRIES=$[$NXTRIES+1]
        else
                NXTRIES=5
        fi
done

NAVEXCONFIRMS=`echo $NAVEXDATA | jq -r '.confirmations'`
NAVEXTIME=`echo $NAVEXDATA | jq -r '.created'`

echo "NAVEXDATA $NAVEXDATA"

echo "NAVEXCONFIRMS" $NAVEXCONFIRMS
echo "NAVEXTIME" $NAVEXTIME

NAVEXTIMESTAMP=`date -d $NAVEXTIME +%s`

echo "NAVEXTIMESTAMP" $NAVEXTIMESTAMP

CIDURL="https://chainz.cryptoid.info/nav/api.dws?q=getblockhash&height=$BLOCKCOUNT"

CIDTRIES=0
while [ "$CIDTRIES" -lt 5 ]; do
        CIDDATA=`curl -s $CIDURL`
        if [ ${#CIDDATA} == 66 ]; then
                NO_WHITESPACE="$(echo -e "${CIDDATA}" | tr -d '[:space:]')"
                if [ ${#NO_WHITESPACE} == 66 ]; then
                        CIDBLOCKHASH=${NO_WHITESPACE:1:64}
                        echo "CIDBLOCKHASH" $CIDBLOCKHASH       
                        CIDTRIES=5
                else
			sleep 1
                        CIDTRIES=$[$CIDTRIES+1]
                fi

        else
		sleep 1
                CIDTRIES=$[$CIDTRIES+1]
        fi
done

CIDTIMEURL="https://chainz.cryptoid.info/nav/api.dws?q=getblocktime&height=$BLOCKCOUNT"

echo "CIDBLOCKHASH" $CIDBLOCKHASH

CIDTRIES=0
while [ "$CIDTRIES" -lt 5 ]; do
        CIDTIMEDATA=`curl -s $CIDTIMEURL`
        if [ ${#CIDTIMEDATA} == 10 ]; then
                NO_WHITESPACE="$(echo -e "${CIDTIMEDATA}" | tr -d '[:space:]')"
                if [ ${#NO_WHITESPACE} == 10 ]; then
                        CIDBLOCKTIME=${NO_WHITESPACE:0:10}
                        echo "CIDBLOCKTIME" $CIDBLOCKTIME
                        CIDTRIES=5
                else
			sleep 1
                        CIDTRIES=$[$CIDTRIES+1]
                fi

        else
		sleep 1
                CIDTRIES=$[$CIDTRIES+1]
        fi
done

ERROR=0

TIME_TOLERANCE=`echo $(($NOW - $TOLERANCE*30))`

echo "TIME_TOLERANCE" $TIME_TOLERANCE

if [ "$NAVEXBLOCKHASH" == "null" ]; then
        MESSAGE="NavExplorer could not return the blockhash"
        echo $MESSAGE
        ERROR=1
elif [ "$NAVEXCONFIRMS" -gt "$TOLERANCE" ]; then
        MESSAGE="NavExplorer determines the NavMonitor is more than $TOLERANCE blocks behind NavExplorer"
        echo $MESSAGE
        ERROR=1
elif [ "$NAVEXBLOCKHASH" != "$BLOCKHASH" ]; then
        MESSAGE="NavExplorer blockhash did not match the NavMonitor blockhash"
        echo $MESSAGE
        ERROR=2
elif [ "$CIDBLOCKHASH" != "$BLOCKHASH" ]; then
        MESSAGE="CryptoID blockhash did not match the NavMonitor blockhash"
        echo $MESSAGE
        ERROR=2
elif [ "$NAVEXBLOCKHASH" != "$CIDBLOCKHASH" ]; then
        MESSAGE="NavExplorer blockhash did not match the CryptoID blockhash"
        echo $MESSAGE
        ERROR=2
elif [ "$NAVEXTIMESTAMP" != "$CIDBLOCKTIME" ]; then
	MESSAGE="NavExplorer and CryptoID block timestamps mismatch"
	echo $MESSAGE
	ERROR=3
elif [ "$NAVEXTIMESTAMP" -lt "$TIME_TOLERANCE" ]; then
	MESSAGE="NavExplorer block timepstamp is older than ($TOLERANCE*30) seconds"
        echo $MESSAGE
        ERROR=3
elif [ "$CIDBLOCKTIME" -lt "$TIME_TOLERANCE" ]; then
	MESSAGE="CryptoID block timepstamp is older than ($TOLERANCE*30) seconds"
	echo $MESSAGE
        ERROR=3
else
	MESSAGE="All Checks Successful"
        echo $MESSAGE;
fi

API_TOKEN="<telegram bot token>"
CHAT_ID="<telegram chat id>"

send() {
        DATA=$1
        curl -s \
        -X POST \
	https://api.telegram.org/bot$API_TOKEN/sendMessage \
        -d text="$MESSAGE %0A%0A$DATA" \
        -d chat_id=$CHAT_ID
}

if [ "$ERROR" != 0 ]; then
        ERROR_MESSAGE=$"Bootstrap Failed -  ERROR $ERROR - $MESSAGE"
        `echo $ERROR_MESSAGE | mail -s 'NavCoin Network Monitor' craig@encrypt-s.com`
	send "Height: $BLOCKCOUNT %0AHash: $BLOCKHASH %0AServer Timestamp: $NOW %0ANavExplorer Hash: $NAVEXBLOCKHASH %0ANavExplorer Timestamp: $NAVEXTIMESTAMP %0ANavExplorer Confirmations: $NAVEXCONFIRMS %0ACryptoID Hash: $CIDBLOCKHASH %0ACryptoID Timestamp: $CIDBLOCKTIME %0ABlock Tolerance: $TOLERANCE"
else
	send "Height: $BLOCKCOUNT %0AHash: $BLOCKHASH"
fi

echo $(date -u) "Network Montior Completed"
