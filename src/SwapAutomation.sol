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
    function swapTokensForTokens(
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint amountIn,
        uint amountOutMin,
        address _from,
        address to,
        uint deadline
    ) public returns (uint[] memory) {
        tokenIn.transferFrom(_from, address(this), amountIn);

        tokenIn.approve(address(uniswapV2Router), amountIn);

        address[] memory path = new address[](2);
        path[0] = address(tokenIn);
        path[1] = address(tokenOut);
        return
            uniswapV2Router.swapExactTokensForTokens(
                amountIn,
                amountOutMin,
                path,
                to,
                deadline
            );
    }

    function swapTokensForETH(
        IERC20 tokenIn,
        uint amountIn,
        uint amountOutMin,
        address _from,
        address to,
        uint deadline
    ) public returns (uint[] memory) {
        tokenIn.transferFrom(_from, address(this), amountIn);

        tokenIn.approve(address(uniswapV2Router), amountIn);

        address[] memory path = new address[](2);
        path[0] = address(tokenIn);
        path[1] = uniswapV2Router.WETH();
        return
            uniswapV2Router.swapExactTokensForETH(
                amountIn,
                amountOutMin,
                path,
                to,
                deadline
            );
    }

    function swapETHForTokens(
        IERC20 tokenOut,
        uint amountOutMin,
        address to,
        uint deadline
    ) public payable returns (uint[] memory) {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(tokenOut);
        return
            uniswapV2Router.swapExactETHForTokens{value: msg.value}(
                amountOutMin,
                path,
                to,
                deadline
            );
    }
    function addAction(
        uint actionId,
        uint256[] calldata action
    ) public returns (uint) {
        require(!actions[actionId].initialized, "Action ID already exists");

        actions[actionId] = SwapAction({
            ownerAddress: address(uint160(action[0])),
            initialized: uintToBool(action[1]), // should convert to bool be used or rather 0 and 1
            duration: action[2],
            timeZero: action[3],
            tokenIn: IERC20(address(uint160(action[4]))),
            tokenOut: IERC20(address(uint160(action[5]))),
            amountIn: action[6],
            from: address(uint160(action[7])),
            to: address(uint160(action[8])),
            isActive: uintToBool(action[9]) //same
        });
        actionIds.push(actionId);
        return actionId;
    }

    function getActionById(
        uint actionId
    )
        public
        view
        returns (
            address ownerAddress,
            bool initialized,
            uint duration,
            uint timeZero,
            IERC20 tokenIn,
            IERC20 tokenOut,
            uint amountIn,
            address from,
            address to,
            bool isActive
        )
    {
        SwapAction storage action = actions[actionId];
        return (
            action.ownerAddress,
            action.initialized,
            action.duration,
            action.timeZero,
            action.tokenIn,
            action.tokenOut,
            action.amountIn,
            action.from,
            action.to,
            action.isActive
        );
    }

    function deleteAction(uint actionId) public {
        require(actions[actionId].initialized, "Action does not exist");
        actions[actionId].isActive = false;
        actions[actionId].initialized = false;
    }

    function setActiveState(uint actionId, bool newIsActive) public {
        require(actions[actionId].initialized, "Action does not exist");
        actions[actionId].isActive = newIsActive;
    }

    function executeAction(uint actionId) public {
        require(
            actions[actionId].initialized,
            "Invalid ID: This automation action does not exist."
        );

        uint256 currentTime = block.timestamp;

        SwapAction storage action = actions[actionId];

        require(action.isActive, "Action is not active");
        require(currentTime >= action.timeZero, "It's too early");

        action.tokenIn.approve(address(uniswapV2Router), action.amountIn);

        address[] memory path = new address[](2);
        path[0] = address(action.tokenIn);
        path[1] = address(action.tokenOut);

        uint[] memory amounts = uniswapV2Router.getAmountsOut(
            action.amountIn,
            path
        );

        uint deadline = currentTime + 1 days;

        uniswapV2Router.swapExactTokensForTokens(
            action.amountIn,
            amounts[amounts.length - 1],
            path,
            action.to,
            deadline
        );

        action.timeZero =
            action.timeZero +
            ((currentTime - action.timeZero) / action.duration) *
            action.duration +
            action.duration;
    }
}
