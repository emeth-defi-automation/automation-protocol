#!/usr/bin/env bash
source .env && \

# Assuming you have an array of structs and another array of uints
STRUCTS="[($ADDRESS_FROM,$USDC_TOKEN,15000000000000000000)]"


cast send \
    --legacy --rpc-url $ALCHEMY \
    --private-key $PRIVATE_KEY2 \
    $TOKEN_DELEGATOR_CONTRACT_ADDRESS "addActionExternal(uint,address,(address,address,uint)[],uint[])(bool)" \
     $1 $TRANSFER_CONTRACT_ADDRESS  "$STRUCTS" "[$1,$UINT_TO,1,180,1718021004221,1,$UINT_USDC,$UINT_FROM,$UINT_TO,15000000000000000000]"