#!/usr/bin/env bash
source .env && \

cast send \
    --legacy --rpc-url $ALCHEMY \
    --private-key $PRIVATE_KEY2 \
    $SWAP_CONTRACT_ADDRESS "addAction(uint,uint[])()" \
    $1 "[$UINT_TO,1,180,1718536511,$UINT_USDC,$UINT_USDT,15000000000000000000,$UINT_FROM,$UINT_TO,1]"