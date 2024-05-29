#!/usr/bin/env bash
source .env && \
cast send \
    --legacy --rpc-url $ALCHEMY \
    --private-key $PRIVATE_KEY \
    $TOKEN_DELEGATOR_CONTRACT_ADDRESS "addAction(uint,address,address,uint,address,address,uint,uint,bool)(uint)" \
     $1 $USDC_TOKEN $USDT_TOKEN 20000000000000000000 \
    $ADDRESS_FROM $ADDRESS_TO \
    1716966159 180 true && \
deactivate
