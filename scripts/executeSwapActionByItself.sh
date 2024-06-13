#!/usr/bin/env bash
source .env && \
cast send --legacy --rpc-url $ALCHEMY $SWAP_CONTRACT_ADDRESS --private-key $PRIVATE_KEY2 "executeAction(uint)" $1 && \
deactivate