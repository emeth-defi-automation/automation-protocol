#!/usr/bin/env bash
source .env && \
cast send --rpc-url $ALCHEMY $TOKEN_DELEGATOR_CONTRACT_ADDRESS --private-key $PRIVATE_KEY "executeAction(uint)(uint[])" $1 && \
deactivate