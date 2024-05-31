#!/usr/bin/env bash
source .env && \
cast send --legacy --gas-price 93686612043 --rpc-url $ALCHEMY $TOKEN_DELEGATOR_CONTRACT_ADDRESS --private-key $PRIVATE_KEY2 "executeAction()()" && \
deactivate