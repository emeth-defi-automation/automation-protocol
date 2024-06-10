#!/usr/bin/env bash
source .env && \

cast send \
    --legacy --rpc-url $ALCHEMY \
    --private-key $PRIVATE_KEY2 \
    $TOKEN_DELEGATOR_CONTRACT_ADDRESS "addActionExternal(uint,address,(address,address,uint)[],uint[])(bool)" \
    $1 0x8Dd675aFA2f097C5F2ea0e95C7c428274fAFE0c9 \
    "[($ADDRESS_FROM,$USDC_TOKEN,$2)]" \
    "[$1,$UINT_TO,1,180,1718021004221,1,1,$UINT_USDC,$UINT_FROM,$UINT_TO,15000000000000000000]"