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
}
