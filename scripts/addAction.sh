#!/usr/bin/env bash
source .env && \
cast send \
    --legacy --rpc-url $ALCHEMY \
    --private-key $PRIVATE_KEY2 \
    $TOKEN_DELEGATOR_CONTRACT_ADDRESS "addAction(uint,address,address,uint,address,address,uint,uint,bool)(uint)" \
     $1 $USDT_TOKEN $USDC_TOKEN  15000000000000000000 \
    $ADDRESS_FROM $ADDRESS_TO \
    1717150946 180 true && \
deactivate