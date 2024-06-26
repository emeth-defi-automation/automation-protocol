source .env && \
cast call --rpc-url $ALCHEMY \
    $USDC_TOKEN "allowance(address,address)(uint)" \
    $ADDRESS_FROM $TOKEN_DELEGATOR_CONTRACT_ADDRESS && \
    cast call --rpc-url $ALCHEMY \
    $USDC_TOKEN "allowance(address,address)(bool)" \
    0x8C33f3Cd815e4C0624E53FadCf0fC21e19125bdD 0x0cFeDdFaE0075714f696D5EbeA3C907a25Ef3030  && \
deactivate