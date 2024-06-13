#!/usr/bin/env bash
source .env && \
cast send --legacy --rpc-url $ALCHEMY \
          --private-key $PRIVATE_KEY_BOGOL \
          $USDC_TOKEN \
          "transfer(address,uint256)" $TRANSFER_CONTRACT_ADDRESS 15000000000000000000