// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract TestAutomation {
    mapping(uint => uint) public actions;
    uint[] public actionIds;

    function addAction(
        uint actionId,
        uint256[] calldata action
    ) public returns (uint) {
        require(actions[actionId] == 0, "Action ID already exists"); // Check if actionId already exists

        actions[actionId] = action[0];
        actionIds.push(actionId);
        return actionId;
    }

    function getActionById(uint actionId) public view returns (uint) {
        require(actions[actionId] != 0, "Action ID does not exist"); // Check if actionId does not exist
        uint action = actions[actionId];
        return action;
    }

    function executeAction(uint actionId) public returns (bool) {
        require(actions[actionId] != 0, "Action ID does not exist"); // Check if actionId does not exist
        actions[actionId] += 1;
        return true;
    }
}
