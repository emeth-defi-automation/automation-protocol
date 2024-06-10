#!/bin/bash

# Run the first script
./scripts/deployTransfer.sh
if [ $? -ne 0 ]; then
  echo "./scripts/deployTransfer.sh failed"
  exit 1
fi

# Run the second script
./scripts/deploySwap.sh
if [ $? -ne 0 ]; then
  echo "./scripts/deploySwap.sh failed"
  exit 1
fi

# Run the third script
./scripts/deployMain.sh
if [ $? -ne 0 ]; then
  echo "./scripts/deployMain.sh failed"
  exit 1
fi

echo "All scripts ran successfully"
