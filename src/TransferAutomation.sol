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

    function uintToBool(uint value) public pure returns (bool) {
        return value != 0;
    }

    function addAction(
        uint actionId,
        uint[] calldata action
    ) public returns (uint) {
        require(!actions[actionId].initialized, "Action ID already exists");

        uint transfersCount = action[5];

        Transfer[] memory transfers = new Transfer[](transfersCount);

        for (uint i = 0; i < transfersCount; i++) {
            uint index = 6 + i * 4;
            transfers[i] = Transfer({
                token: IERC20(address(uint160(action[index]))),
                from: address(uint160(action[index + 1])),
                to: address(uint160(action[index + 2])),
                amount: action[index + 3]
            });
        }

        TransferAction storage newAction = actions[actionId];
        newAction.ownerAddress = address(uint160(action[0]));
        newAction.initialized = uintToBool(action[1]);
        newAction.duration = action[2];
        newAction.timeZero = action[3];
        newAction.isActive = uintToBool(action[4]);

        for (uint i = 0; i < transfersCount; i++) {
            newAction.transfers.push(transfers[i]);
        }

        actionIds.push(actionId);
        return actionId;
    }
}
