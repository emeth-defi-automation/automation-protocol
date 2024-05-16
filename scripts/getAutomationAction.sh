#!/usr/bin/env bash
source .env && \
cast call --rpc-url $ALCHEMY $TOKEN_DELEGATOR_CONTRACT_ADDRESS "getAutomationAction(uint)((uint,uint,address,address,uint,address,address,uint))" $1 && \
deactivate