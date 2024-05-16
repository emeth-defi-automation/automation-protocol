#!/usr/bin/env bash
source .env && \
cast send \
    --rpc-url $ALCHEMY \
    --private-key $PRIVATE_KEY \
    $TOKEN_DELEGATOR_CONTRACT_ADDRESS "addAction(address,address,uint,uint,address,address,uint,uint)(uint)" \
    0xD418937d10c9CeC9d20736b2701E506867fFD85f 0x9D16475f4d36dD8FC5fE41F74c9F44c7EcCd0709 20000000000000000000 \
    15000000000000000000 0x0577b55800816b6A2Da3BDbD3d862dce8e99505D 0x8545845EF4BD63c9481Ae424F8147a6635dcEF87 \
    1715998201 1 && \
deactivate