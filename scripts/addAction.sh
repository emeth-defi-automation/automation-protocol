#!/usr/bin/env bash
source .env && \
cast send \
    --legacy --rpc-url $ALCHEMY \
    --private-key $PRIVATE_KEY2 \
    $TOKEN_DELEGATOR_CONTRACT_ADDRESS "addAction(uint,address,address,uint,address,address,uint,uint,bool)(uint)" \
     $1 $USDT_TOKEN $USDC_TOKEN  20000000000000000000 \
    $ADDRESS_FROM $ADDRESS_TO \
    1717150946 180 true && \
deactivate

cast call --rpc-url https://eth-sepolia.g.alchemy.com/v2/SRIsNk0G9XuPgHC7fAKMiLhA98gzaLmN 0x054E1324CF61fe915cca47C48625C07400F1B587 "allowance(address,address)(uint256)" 0x0577b55800816b6A2Da3BDbD3d862dce8e99505D 0x7218042e5617FF2102166a03348fd29F8DcE37fB && cast call --rpc-url https://eth-sepolia.g.alchemy.com/v2/SRIsNk0G9XuPgHC7fAKMiLhA98gzaLmN 0x7218042e5617FF2102166a03348fd29F8DcE37fB "allowance(address,address)(bool)" 0x8545845EF4BD63c9481Ae424F8147a6635dcEF87 0x0577b55800816b6A2Da3BDbD3d862dce8e99505D