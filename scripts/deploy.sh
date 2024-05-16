#!/usr/bin/env bash
source .env && \
forge create --rpc-url $ALCHEMY --private-key $PRIVATE_KEY src/TokenDelegator.sol:TokenDelegator && \
deactivate