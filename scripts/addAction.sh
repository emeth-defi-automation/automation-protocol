#!/usr/bin/env bash
source .env && \
cast send \
    --rpc-url $ALCHEMY \
    --private-key $PRIVATE_KEY \
    $TOKEN_DELEGATOR_CONTRACT_ADDRESS "addAction(address,address,uint,uint,address,address,uint,uint)(uint)" \
    $USDC_TOKEN $USDT_TOKEN 20000000000000000000 \
    15000000000000000000 $ADDRESS_FROM $ADDRESS_TO \
    1715998201 $1 && \
deactivate