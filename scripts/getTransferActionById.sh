#!/usr/bin/env bash
source .env && \

cast call \
    --legacy --rpc-url $ALCHEMY \
    --private-key $PRIVATE_KEY2 \
    $TRANSFER_CONTRACT_ADDRESS "getActionById(uint)(address,bool,uint,uint,bool,(address,address,address,uint)[])" \
    $1