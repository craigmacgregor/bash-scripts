#!/usr/bin/env bash

echo $(date -u) "Updating Bootstrap"

VERSION="4.7.1"
USER="XXXXX"

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
                NXTRIES=$[$TRIES+1]
        else
                NXTRIES=5
        fi
done

NAVEXBEST=`echo $NAVEXDATA | jq -r '.best'`

echo "NAVEXBEST" $NAVEXBEST

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
                        CIDTRIES=$[$TRIES+1]
                fi

        else
                CIDTRIES=$[$TRIES+1]
        fi
done

ERROR=0

if [ "$NAVEXBLOCKHASH" == "null" ]; then
        MESSAGE="NavExplorer could not return the blockhash"
        echo $MESSAGE
        ERROR=1
elif [ "$NAVEXBEST" == "false" ]; then
        MESSAGE="NavExplorer determines the bootstrap is not up to date"
        echo $MESSAGE
        ERROR=1
elif [ "$NAVEXBLOCKHASH" != "$BLOCKHASH" ]; then
        MESSAGE="NavExplorer blockhash did not match the bootstrap blockhash"
        echo $MESSAGE
        ERROR=2
#elif [ "$CIDBLOCKHASH" != "$BLOCKHASH" ]; then
#        MESSAGE="CryptoID blockhash did not match the bootstrap blockhash"
#        echo $MESSAGE
#        ERROR=2
#elif [ "$NAVEXBLOCKHASH" != "$CIDBLOCKHASH" ]; then
#        MESSAGE="NavExplorer blockhash did not match the CryptoID blockhash"
#        echo $MESSAGE
#        ERROR=2
else
        echo "SUCCESS";
fi

if [ "$ERROR" != 0 ]; then
        ERROR_MESSAGE=$"Bootstrap Failed -  ERROR $ERROR - $MESSAGE"
        `echo $ERROR_MESSAGE | mail -s 'NavCoin Bootstrap' craig@encrypt-s.com`
        exit 0;
fi

/home/$USER/navcoin-$VERSION/bin/navcoin-cli stop

wait

cd /home/$USER/.navcoin4

ARCHIVE="bootstrap-navcoin_mainnet"

tar cvf $ARCHIVE-new.tar blocks chainstate

/home/$USER/navcoin-$VERSION/bin/navcoind &

cp $ARCHIVE-new.tar /home/$USER/www/navcoin-bootstrap/$ARCHIVE.tar

rm $ARCHIVE-new.tar

echo $(date -u) "Bootstrap Updated"
