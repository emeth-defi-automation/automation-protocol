#!/usr/bin/env bash
source .env && \

cast send \
    --legacy --rpc-url $ALCHEMY \
    --private-key $PRIVATE_KEY2 \
    0x2A08C5EB47c0c110ab71C8c9db80Aba35384ED96 "addActionExternal(uint,uint[])(bool)" \
    111 "[1,1,180,1718021004221,1,15000000000000000000]"