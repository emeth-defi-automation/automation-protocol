// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;
import "forge-std/console.sol";
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

contract TokenDelegator {
    IUniswapV2Router public uniswapV2Router;

    constructor() {
        uniswapV2Router = IUniswapV2Router(
            0x87aE49902B749588c15c5FE2A6fE6a1067a5bea0
        );
    }

    mapping(address => mapping(address => bool)) public approvals;

    struct Payment {
        uint256 amount;
        IERC20 token;
    }

    struct Transfer {
        IERC20 token;
        address from;
        address to;
        uint256 amount;
    }

    struct AutomationsAction {
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

    mapping(uint => AutomationsAction) public actions;
    uint[] public actionIds;

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
        uint actionId,
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint amountIn,
        address _from,
        address to,
        uint timeZero,
        uint duration,
        bool isActive
    ) public returns (uint) {
        require(!actions[actionId].initialized, "Action ID already exists");

        actions[actionId] = AutomationsAction({
            ownerAddress: msg.sender,
            initialized: true,
            duration: duration,
            timeZero: timeZero,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: amountIn,
            from: _from,
            to: to,
            isActive: isActive
        });
        actionIds.push(actionId);
        return actionId;
    }

    function addActionExternal(
        uint actionId,
        address _contractAddress,
        // Payment[] payments, move to execute
        uint[] calldata args
    ) public returns (bool) {
        require(!actions[actionId].initialized, "Action ID already exists");

        bytes memory data = abi.encodeWithSignature(
            "addAction(uint256,uint256[])",
            actionId,
            args
        );
        (bool success, ) = _contractAddress.call(data);
        require(success, "External call failed");

        return success;
    }

    function getAutomationAction(
        uint _id
    ) public view returns (AutomationsAction memory) {
        require(
            actions[_id].initialized,
            "Invalid ID: This automation action does not exist."
        );
        require(
            actions[_id].ownerAddress == msg.sender,
            "Only the owner can toggle the isActive status."
        );
        return actions[_id];
    }

    function setAutomationActiveState(uint _id, bool isActive) public {
        require(
            actions[_id].initialized,
            "Invalid ID: This automation action does not exist."
        );
        require(
            actions[_id].ownerAddress == msg.sender,
            "Only the owner can toggle the isActive status."
        );
        actions[_id].isActive = isActive;
    }

    function executeAction(uint actionId) public {
        require(
            actions[actionId].initialized,
            "Invalid ID: This automation action does not exist."
        );
        uint256 currentTime = block.timestamp;

        AutomationsAction storage action = actions[actionId];

        require(action.isActive, "Action is not active");
        require(currentTime >= action.timeZero, "It's too early");
        require(
            action.tokenIn.allowance(action.from, address(this)) >=
                action.amountIn,
            "Not enough allowance"
        );

        action.timeZero =
            action.timeZero +
            ((currentTime - action.timeZero) / action.duration) *
            action.duration +
            action.duration;

        address[] memory path = new address[](2);
        path[0] = address(action.tokenIn);
        path[1] = address(action.tokenOut);

        uint[] memory amounts = uniswapV2Router.getAmountsOut(
            action.amountIn,
            path
        );

        uint deadline = currentTime + 1 days;

        swapTokensForTokens(
            action.tokenIn,
            action.tokenOut,
            action.amountIn,
            amounts[amounts.length - 1],
            action.from,
            action.to,
            deadline
        );
    }
}
