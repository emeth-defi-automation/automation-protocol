// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract TransferAutomation {
    struct Transfer {
        IERC20 token;
        address from;
        address to;
        uint256 amount;
    }

    struct TransferAction {
        address ownerAddress;
        bool initialized;
        uint duration;
        uint timeZero;
        bool isActive;
        Transfer[] transfers;
    }

    mapping(uint => TransferAction) public actions;
    uint[] public actionIds;

    function addAction(uint actionId, uint[] action) public returns (uint) {
        require(!actions[actionId].initialized, "Action ID already exists");

        uint transfersCount = action[0];

        Transfer[] memory transfers = new Transfer[](transfersCount);

        for (uint i = 0; i < transfersCount; i++) {
            uint index = 1 + i * 4;
            transfers[i] = Transfer({
                token: address(input[index]),
                from: address(input[index + 1]),
                to: address(input[index + 2]),
                amount: input[index + 3]
            });
        }

        actions[actionId] = TransferAction({
            ownerAddress: action[0],
            initialized: action[1],
            duration: action[2],
            timeZero: action[3],
            isActive: action[4],
            transfers: transfers
        });

        actionIds.push(actionId);
        return actionId;
    }
}
