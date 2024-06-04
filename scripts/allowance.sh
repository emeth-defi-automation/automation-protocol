source .env && \
cast call --rpc-url $ALCHEMY \
    $USDT_TOKEN "allowance(address,address)(uint)" \
    $ADDRESS_FROM $TOKEN_DELEGATOR_CONTRACT_ADDRESS && \
    cast call --rpc-url $ALCHEMY \
    $USDT_TOKEN "allowance(address,address)(bool)" \
    0x0577b55800816b6A2Da3BDbD3d862dce8e99505D 0x7218042e5617FF2102166a03348fd29F8DcE37fB  && \
deactivate