#!/usr/bin/env bash

echo $(date -u) "Updating Bootstrap"

AWS="/home/bootstrap/.local/bin/aws"

VERSION="4.5.2"

BLOCKCOUNT=`/home/bootstrap/navcoin-$VERSION/bin/navcoin-cli getblockcount`
BLOCKHASH=`/home/bootstrap/navcoin-$VERSION/bin/navcoin-cli getblockhash $BLOCKCOUNT`

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
elif [ "$CIDBLOCKHASH" != "$BLOCKHASH" ]; then
        MESSAGE="CryptoID blockhash did not match the bootstrap blockhash"
        echo $MESSAGE
        ERROR=2
elif [ "$NAVEXBLOCKHASH" != "$CIDBLOCKHASH" ]; then
        MESSAGE="NavExplorer blockhash did not match the CryptoID blockhash"
        echo $MESSAGE
        ERROR=2
else
        echo "SUCCESS";
fi

if [ "$ERROR" != 0 ]; then
        ERROR_MESSAGE=$"Bootstrap Failed -  ERROR $ERROR - $MESSAGE"
        `echo $ERROR_MESSAGE | mail -s 'NavCoin Bootstrap' craig@encrypt-s.com`
        exit 0;
fi

/home/bootstrap/navcoin-$VERSION/bin/navcoin-cli stop

wait

cd /home/bootstrap/.navcoin4

ARCHIVE="bootstrap-navcoin_mainnet"

tar cvf $ARCHIVE-new.tar blocks chainstate

/home/bootstrap/navcoin-$VERSION/bin/navcoind &

$AWS s3 cp $ARCHIVE-new.tar s3://navcoin-bootstrap/

rm $ARCHIVE-new.tar

$AWS s3 mv s3://navcoin-bootstrap/$ARCHIVE-new.tar s3://navcoin-bootstrap/$ARCHIVE.tar --acl public-read

echo $(date -u) "Bootstrap Updated"
