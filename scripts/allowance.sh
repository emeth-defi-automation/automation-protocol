source .env && \
cast call --rpc-url $ALCHEMY \
    $USDT_TOKEN "allowance(address,address)(uint)" \
    $ADDRESS_FROM $TOKEN_DELEGATOR_CONTRACT_ADDRESS && \
    cast call --rpc-url $ALCHEMY \
    $USDT_TOKEN "allowance(address,address)(bool)" \
    $ADDRESS_FROM $ADDRESS_TO  && \
deactivate