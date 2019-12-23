#!/usr/bin/env bash

echo "----------------------------------------------------------"
echo $(date -u) "Running Network Monitor"

VERSION="4.7.2"
USER="<USER>"
TOLERANCE=10
MAX_TRIES=3
MONITOR_TRIES=0
MAX_API_TRIES=5
API_SLEEP=2
MONITOR_SLEEP=5
DEPTH=5

while [ "$MONITOR_TRIES" -lt "$MAX_TRIES" ]; do

	NOW=`date +"%s"`

	echo "NOW" $NOW

	BLOCKCOUNT=`/home/$USER/navcoin-$VERSION/bin/navcoin-cli getblockcount`
	BLOCKCOUNT=$[$BLOCKCOUNT - $DEPTH]
	BLOCKHASH=`/home/$USER/navcoin-$VERSION/bin/navcoin-cli getblockhash $BLOCKCOUNT`

	echo "BLOCKCOUNT" $BLOCKCOUNT
	echo "BLOCKHASH" $BLOCKHASH

	NAVEXURL="https://api.navexplorer.com/api/block/$BLOCKCOUNT"

	NXTRIES=0
	while [ "$NXTRIES" -lt "$MAX_API_TRIES" ]; do
		NAVEXDATA=`curl -s $NAVEXURL`
		NAVEXBLOCKHASH=`echo $NAVEXDATA | jq -r '.hash'`
		echo "NAVEXBLOCKHASH" $NAVEXBLOCKHASH
		if [ "$NAVEXBLOCKHASH" == "null" ]; then
			NXTRIES=$[$NXTRIES+1]
			echo "Invalid block data from NavExplorer: Attempt $NXTRIES, Data $NAVEXDATA"
			sleep $API_SLEEP
		else
			NXTRIES=$[MAX_API_TRIES]
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
	while [ "$CIDTRIES" -lt "$MAX_API_TRIES" ]; do
		CIDDATA=`curl -s $CIDURL`
		if [ ${#CIDDATA} == 66 ]; then
			NO_WHITESPACE="$(echo -e "${CIDDATA}" | tr -d '[:space:]')"
			if [ ${#NO_WHITESPACE} == 66 ]; then
				CIDBLOCKHASH=${NO_WHITESPACE:1:64}
				echo "CIDBLOCKHASH" $CIDBLOCKHASH       
				CIDTRIES=$[MAX_API_TRIES]
			else
				sleep $API_SLEEP
				echo "Invalid blockhash from CryptoID: Attempt $CIDTRIES, Data $CIDDATA"
				CIDTRIES=$[$CIDTRIES+1]
			fi

		else
			sleep $API_SLEEP
			echo "Failed to get blockhash from CryptoID: Attempt $CIDTRIES, Data $CIDDATA"
			CIDTRIES=$[$CIDTRIES+1]
		fi
	done

	CIDTIMEURL="https://chainz.cryptoid.info/nav/api.dws?q=getblocktime&height=$BLOCKCOUNT"

	echo "CIDBLOCKHASH" $CIDBLOCKHASH

	CIDTRIES=0
	while [ "$CIDTRIES" -lt "$MAX_API_TRIES" ]; do
		CIDTIMEDATA=`curl -s $CIDTIMEURL`
		if [ ${#CIDTIMEDATA} == 10 ]; then
			NO_WHITESPACE="$(echo -e "${CIDTIMEDATA}" | tr -d '[:space:]')"
			if [ ${#NO_WHITESPACE} == 10 ]; then
				CIDBLOCKTIME=${NO_WHITESPACE:0:10}
				echo "CIDBLOCKTIME" $CIDBLOCKTIME
				CIDTRIES=$[MAX_API_TRIES]
			else
				sleep $API_SLEEP
				echo "Invalid blockhash from CryptoID: Attempt $CIDTRIES, Data $CIDTIMEDATA"
				CIDTRIES=$[$CIDTRIES+1]
			fi

		else
			sleep $API_SLEEP
			echo "Failed to get time from CryptoID: Attempt $CIDTRIES, Data $CIDTIMEDATA"
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
		MESSAGE="NavExplorer blockhash did not match the NavMonitor blockhash [$BLOCKHASH] [$NAVEXBLOCKHASH]"
		echo $MESSAGE
		ERROR=2
	elif [ "$CIDBLOCKHASH" != "$BLOCKHASH" ]; then
		MESSAGE="CryptoID blockhash did not match the NavMonitor blockhash [$BLOCKHASH] [$CIDBLOCKHASH]"
		echo $MESSAGE
		ERROR=2
	elif [ "$NAVEXBLOCKHASH" != "$CIDBLOCKHASH" ]; then
		MESSAGE="NavExplorer blockhash did not match the CryptoID blockhash [$NAVEXBLOCKHASH] [$CIDBLOCKHASH]"
		echo $MESSAGE
		ERROR=2
	elif [ "$NAVEXTIMESTAMP" != "$CIDBLOCKTIME" ]; then
		MESSAGE="NavExplorer and CryptoID block timestamps mismatch [$NAVEXTIMESTAMP] [$CIDBLOCKTIME]"
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

	if [ "$ERROR" != 0 ]; then
		MONITOR_TRIES=$[MONITOR_TRIES+1]
		sleep $MONITOR_SLEEP
	else
		MONITOR_TRIES=[$MAX_TRIES]
	fi

done #end while

API_TOKEN="<TOKEN>"
CHAT_ID="<ID>"

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
        `echo $ERROR_MESSAGE | mail -s 'NavCoin Network Monitor' <EMAIL>`
	send "Height: $BLOCKCOUNT %0AHash: $BLOCKHASH %0AServer Timestamp: $NOW %0ANavExplorer Hash: $NAVEXBLOCKHASH %0ANavExplorer Timestamp: $NAVEXTIMESTAMP %0ANavExplorer Confirmations: $NAVEXCONFIRMS %0ACryptoID Hash: $CIDBLOCKHASH %0ACryptoID Timestamp: $CIDBLOCKTIME %0ABlock Tolerance: $TOLERANCE %0A%0A@proletesseract"
else
	send "Height: $BLOCKCOUNT %0AHash: $BLOCKHASH"
fi

echo $(date -u) "Network Montior Completed"

echo "----------------------------------------------------------"
