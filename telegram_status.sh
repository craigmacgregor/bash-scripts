#!/bin/bash

apiToken=<TOKEN>
chatId=<CHAT_ID>

send() {
        message=$1
        curl -s \
        -X POST \
        https://api.telegram.org/bot$apiToken/sendMessage \
        -d text="$message" \
        -d chat_id=$chatId
}

send_output() {
        command=$1
        ~/navcoin-core/src/navcoin-cli -testnet $command > /tmp/rpc.out
        curl \
        -F chat_id=$chatId \
        -F document=@"/tmp/rpc.out" \
        -F caption="$command output" https://api.telegram.org/bot$apiToken/sendDocument

}

BLOCKS=`~/navcoin-core/src/navcoin-cli -testnet getinfo|jq .blocks`
BESTHASH=`~/navcoin-core/src/navcoin-cli -testnet getbestblockhash`
PROPOSALS=`~/navcoin-core/src/navcoin-cli -testnet listproposals|sha256sum`

send_output listproposals

send "Height: $BLOCKS%0AHash: $BESTHASH%0ACFund: $PROPOSALS"
