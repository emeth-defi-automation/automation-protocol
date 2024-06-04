source .env && \
cast call --rpc-url $ALCHEMY \
    $TOKEN_DELEGATOR_CONTRACT_ADDRESS "approve(address)()" \
    $ADDRESS_TO && \
deactivate