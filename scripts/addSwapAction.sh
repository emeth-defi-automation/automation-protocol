#!/usr/bin/env bash
source .env && \

cast send \
    --legacy --rpc-url $ALCHEMY \
    --private-key $PRIVATE_KEY2 \
    $TOKEN_DELEGATOR_CONTRACT_ADDRESS "addActionExternal(uint,address,(address,address,uint)[],uint[])(bool)" \
    $1 $Swap_CONTRACT_ADDRESS \
    "[($ADDRESS_FROM,$USDC_TOKEN,$2)]" \
    "[$1,$UINT_TO,1,180,1718021004221,$UINT_USDC,$UINT_UDST,15000000000000000000,$UINT_FROM,$UINT_TO,1]"