#!/usr/bin/env bash
source .env && \
cast send --legacy --rpc-url $ALCHEMY $TOKEN_DELEGATOR_CONTRACT_ADDRESS --private-key $PRIVATE_KEY2 "executeAction(uint)()" $1 && \
deactivate