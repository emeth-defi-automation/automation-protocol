#!/usr/bin/env bash
source .env && \

cast call \
    --legacy --rpc-url $ALCHEMY \
    --private-key $PRIVATE_KEY2 \
    $SWAP_CONTRACT_ADDRESS "getActionById(uint)(address,bool,uint,uint,address,address,uint,address,address,bool)" \
    $1