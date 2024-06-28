#!/usr/bin/env bash
source .env && \
cast send \
    --legacy --rpc-url $ALCHEMY \
    --private-key $PRIVATE_KEY \
    $USDC_TOKEN "approve(address,uint256)(bool)" \
    $TOKEN_DELEGATOR_CONTRACT_ADDRESS $1 && \
deactivate