#!/usr/bin/env bash
source .env && \
cast call \
    --rpc-url $ALCHEMY \
    $USDC_TOKEN "balanceOf(address)(uint256)" \
    $1  && \
deactivate


