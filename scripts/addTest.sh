#!/usr/bin/env bash
source .env && \

cast send \
    --legacy --rpc-url $ALCHEMY \
    --private-key $PRIVATE_KEY2 \
    $TOKEN_DELEGATOR_CONTRACT_ADDRESS "addActionExternal(uint,address,(address,address,uint)[],uint[])(bool)" \
    $1 $TEST_CONTRACT_ADDRESS \
    "[($ADDRESS_FROM,$USDC_TOKEN,$2)]" \
    "[145]"