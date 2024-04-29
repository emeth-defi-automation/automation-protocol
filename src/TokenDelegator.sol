// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

contract TokenDelegator {
    ISwapRouter public immutable swapRouter;
    mapping(address => mapping(address => bool)) public approvals;

    uint24 public constant poolFee = 3000;

    /// @param _swapRouter The address of the Uniswap v3 router
    constructor(ISwapRouter _swapRouter) {
        swapRouter = _swapRouter;
    }

    /// @dev A struct to represent a token transfer
    struct Transfer {
        IERC20 token;
        address from;
        address to;
        uint256 amount;
    }

    /// @notice Approve a user to spend tokens on behalf of the sender
    /// @param _user The address of the user to approve
    function approve(address _user) public {
        approvals[_user][msg.sender] = true;
    }

    /// @notice Check if a spender is approved to spend tokens on behalf of an owner
    /// @param _owner The address of the token owner
    /// @param _spender The address of the token spender
    /// @return true if the spender is approved, false otherwise
    function allowance(address _owner, address _spender) public view returns (bool) {
        return approvals[_owner][_spender];
    }

    /// @notice Transfer tokens from one address to another
    /// @param token The token to transfer
    /// @param _from The address to transfer tokens from
    /// @param _to The address to transfer tokens to
    /// @param _amount The amount of tokens to transfer
    function transferToken(IERC20 token, address _from, address _to, uint256 _amount) public {
        require(approvals[msg.sender][_from], "TokenDelegator: not approved");
        token.transferFrom(_from, address(this), _amount);
        token.transfer(_to, _amount);
    }

    /// @notice Transfer multiple tokens from various addresses to various addresses
    /// @param transfers An array of Transfer structs representing the transfers to make
    function transferBatch(Transfer[] memory transfers) public {
        for (uint256 i = 0; i < transfers.length; i++) {
            Transfer memory t = transfers[i];
            require(approvals[msg.sender][t.from], "TokenDelegator: not approved for all tokens");
            t.token.transferFrom(t.from, address(this), t.amount);
            t.token.transfer(t.to, t.amount);
        }
    }

    /// @notice Swap one token for another
    /// @param tokenIn The token to swap from
    /// @param tokenOut The token to swap to
    /// @param _from The address to swap tokens from
    /// @param _to The address to swap tokens to
    /// @param _amount The amount of tokens to swap
    function swapTokens(IERC20 tokenIn, IERC20 tokenOut, address _from, address _to, uint256 _amount) public {
        require(approvals[msg.sender][_from], "TokenDelegator: not approved");
        tokenIn.transferFrom(_from, address(this), _amount);

        TransferHelper.safeApprove(address(tokenIn), address(swapRouter), _amount);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: address(tokenIn),
            tokenOut: address(tokenOut),
            fee: 3000,
            recipient: _to,
            deadline: block.timestamp + 1 hours,
            amountIn: _amount,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        swapRouter.exactInputSingle(params);
    }
}