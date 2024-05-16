// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

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
}

contract TokenDelegator {
    IUniswapV2Router public uniswapV2Router;

    constructor() {
        uniswapV2Router = IUniswapV2Router(
            0x87aE49902B749588c15c5FE2A6fE6a1067a5bea0
        );
    }

    mapping(address => mapping(address => bool)) public approvals;

    // Define the Transfer struct
    struct Transfer {
        IERC20 token;
        address from;
        address to;
        uint256 amount;
    }

    // Define AutomationAction struct, maybe should be changed to AutomationDCAAction
    struct AutomationsAction {
        uint delay;
        uint date;
        IERC20 tokenIn;
        IERC20 tokenOut;
        uint amountIn;
        uint amountOutMin;
        address from;
        address to;
        uint deadline;
    }

    mapping(uint => AutomationsAction) public actions;
    uint public nextAutomationActionId = 1;

    function approve(address _user) public {
        approvals[_user][msg.sender] = true;
    }

    function allowance(
        address _owner,
        address _spender
    ) public view returns (bool) {
        return approvals[_owner][_spender];
    }

    function transferToken(
        IERC20 token,
        address _from,
        address _to,
        uint256 _amount
    ) public {
        require(approvals[msg.sender][_from], "TokenDelegator: not approved");
        token.transferFrom(_from, address(this), _amount);
        token.transfer(_to, _amount);
    }

    function transferBatch(Transfer[] memory transfers) public {
        for (uint256 i = 0; i < transfers.length; i++) {
            Transfer memory t = transfers[i];
            require(
                approvals[msg.sender][t.from],
                "TokenDelegator: not approved for all tokens"
            );
            t.token.transferFrom(t.from, address(this), t.amount);
            t.token.transfer(t.to, t.amount);
        }
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
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint amountIn,
        uint amountOutMin,
        address _from,
        address to,
        uint deadline,
        uint _delayDays
    ) public returns (uint) {
        actions[nextAutomationActionId] = AutomationsAction({
            delay: _delayDays * 1 days,
            date: 0,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: amountIn,
            amountOutMin: amountOutMin,
            from: _from,
            to: to,
            deadline: deadline
        });
        nextAutomationActionId++;
        return nextAutomationActionId;
    }

    function getAutomationAction(
        uint _id
    ) public view returns (AutomationsAction memory) {
        require(
            _id > 0 && _id < nextAutomationActionId,
            "Invalid ID: This automation action does not exist."
        );
        return actions[_id];
    }

    function executeAction(uint _id) public returns (uint[] memory) {
        require(_id < nextAutomationActionId, "Action does not exist.");
        AutomationsAction storage action = actions[_id];

        require(
            block.timestamp >= action.date + action.delay,
            "It is too early to execute this action again."
        );
        // obliczac estimatedAmount
        action.date = block.timestamp;

        return
            swapTokensForTokens(
                action.tokenIn,
                action.tokenOut,
                action.amountIn,
                action.amountOutMin,
                action.from,
                action.to,
                action.deadline
            );
    }
}
