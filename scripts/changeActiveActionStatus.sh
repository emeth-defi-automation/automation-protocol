#!/usr/bin/env bash
source .env && \
cast send \
    --legacy --rpc-url $ALCHEMY \
    --private-key $PRIVATE_KEY \
    $TOKEN_DELEGATOR_CONTRACT_ADDRESS "setAutomationActiveState(uint,bool)()" \
    $1 $2
deactivate