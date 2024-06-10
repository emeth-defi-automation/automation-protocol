// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract ArrayTester {
    mapping(uint => uint[]) public actions;

    function addActionExternal(
        uint actionId,
        uint[] calldata action
    ) public returns (bool) {
        actions[actionId] = action;
        return true;
    }
}
