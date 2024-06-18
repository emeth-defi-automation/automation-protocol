// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ISwapAutomation {
    function addAction(
        uint actionId,
        uint256[] calldata action
    ) external returns (uint);
    function setActiveState(uint actionId, bool newIsActive) external;
    function executeAction(uint actionId) external;
}
