#!/usr/bin/env bash
source .env && \
cast call --rpc-url $ALCHEMY --private-key $PRIVATE_KEY2 \
$TOKEN_DELEGATOR_CONTRACT_ADDRESS "getAutomationAction(uint)((address,bool,uint,uint,address,address,uint,address,address,bool))" $1 && \
deactivate