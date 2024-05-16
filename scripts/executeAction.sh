#!/usr/bin/env bash
source .env && \
cast call --rpc-url $ALCHEMY $TOKEN_DELEGATOR_CONTRACT_ADDRESS "executeAction(uint)(uint[])" 1 
deactivate