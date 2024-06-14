#!/usr/bin/env bash
source .env && \

cast call \
    --legacy --rpc-url $ALCHEMY \
    --private-key $PRIVATE_KEY2 \
    $TOKEN_DELEGATOR_CONTRACT_ADDRESS "getPaymentById(uint)(address,bool,(address,address,uint)[])" \
    $1