// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';

contract TokenDelegator {
    ISwapRouter public immutable swapRouter;
    mapping(address => mapping(address => bool)) public approvals;

    uint24 public constant poolFee = 3000;
    
    constructor(ISwapRouter _swapRouter) {
        swapRouter = _swapRouter;
    }

    // Define the Transfer struct
    struct Transfer {
        IERC20 token;
        address from;
        address to;
        uint256 amount;
    }

    function approve(address _user) public {
        approvals[_user][msg.sender] = true;
    }
    
    function allowance(address _owner, address _spender) public view returns (bool) {
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
            // require(approvals[msg.sender][t.from], "TokenDelegator: not approved for all tokens");
            t.token.transferFrom(t.from, address(this), t.amount);
            t.token.transfer(t.to, t.amount);
        }
    }

    function swapTokens(
    IERC20 tokenIn,
    IERC20 tokenOut,
    address _from,
    address _to,
    uint256 _amount
) public {
    require(approvals[msg.sender][_from], "TokenDelegator: not approved");
    tokenIn.transferFrom(_from, address(this), _amount);

    TransferHelper.safeApprove(address(tokenIn), address(swapRouter), _amount);

    ISwapRouter.ExactInputSingleParams memory params =
        ISwapRouter.ExactInputSingleParams({
            tokenIn: address(tokenIn),
            tokenOut: address(tokenOut),
            fee: 3000, 
            recipient: _to,
            deadline: block.timestamp + 1 hours, 
            amountIn: _amount,
            amountOutMinimum: 0, 
            sqrtPriceLimitX96: 0 
        });

    uint256 amountOut = swapRouter.exactInputSingle(params);

}
}
