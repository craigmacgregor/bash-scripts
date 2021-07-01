#!/usr/bin/env bash

echo "#######################################################"

echo $(date -u) "stopping navcoind"

/<path>/navcoin-cli stop

SLEEP1=0
while [ "$SLEEP1" -lt 6 ]; do
	STOP_ERROR=$(/<path>/navcoin-cli getinfo 2>&1 >/dev/null)
	if [ "$STOP_ERROR" == "error: couldn't connect to server" ]; then
		echo "shutdown successful"
		SLEEP1=6
	else	
		echo "waiting for shutdown..."
		SLEEP1=$[$SLEEP1+1]
		sleep 10s
	fi
done

echo $(date -u) "starting navcoind"

/<path>/navcoind &

SLEEP2=0
while [ "$SLEEP2" -lt 15 ]; do
	START=$(/<path>/navcoin-cli getinfo | jq -r '.testnet')
        if [ "$START" == "false" ]; then
		echo "startup successful"
                SLEEP2=15
        else    
                echo "waiting for startup..." 
                SLEEP2=$[$SLEEP2+1]
                sleep 60s
        fi

done

echo $(date -u) "unlocking for staking"

UNLOCK=$(/<path>/navcoin-cli walletpassphrase '<password>' 999999999 true)

SLEEP3=0
while [ "$SLEEP3" -lt 6 ]; do
        STAKING=$(/<path>/navcoin-cli signmessage <address> 'test' 2>&1 >/dev/null | sed -n '3 p')
        if [ "${STAKING}" == "Error: Wallet is unlocked for staking or mixing only." ]; then
                echo "wallet is unlocked for staking"
		SLEEP3=6
        else
                echo "testing staking..."
                SLEEP3=$[$SLEEP3+1]
                sleep 10s
        fi
done


echo $(date -u) "restarted complete"

echo "#######################################################"

