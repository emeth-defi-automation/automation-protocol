// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IUniswapV2Router {
    function WETH() external pure returns (address);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

contract SwapAutomation {
    struct SwapAction {
        address ownerAddress;
        bool initialized;
        uint duration;
        uint timeZero;
        IERC20 tokenIn;
        IERC20 tokenOut;
        uint amountIn;
        address from;
        address to;
        bool isActive;
    }

    mapping(uint => SwapAction) public actions;
    uint[] public actionIds;

    IUniswapV2Router public uniswapV2Router;

    constructor() {
        uniswapV2Router = IUniswapV2Router(
            0x87aE49902B749588c15c5FE2A6fE6a1067a5bea0
        );
    }
    function uintToBool(uint value) public pure returns (bool) {
        return value != 0;
    }
    function addAction(uint actionId, uint action) public returns (uint) {
        require(!actions[actionId].initialized, "Action ID already exists");

        actions[actionId] = SwapAction({
            ownerAddress: address(action[0]),
            initialized: action[1], // should convert to bool be used or rather 0 and 1
            duration: action[2],
            timeZero: action[3],
            tokenIn: address(action[4]),
            tokenOut: address(action[5]),
            amountIn: action[6],
            from: address(action[7]),
            to: address(action[8]),
            isActive: action[9] //same
        });
        actionIds.push(actionId);
        return actionId;
    }
}
