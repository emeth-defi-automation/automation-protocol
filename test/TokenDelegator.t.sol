// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {TokenDelegator} from "src/TokenDelgator.sol";

interface IMintableERC20 is IERC20 {
    function mint(address to, uint256 amount) external returns (bool);
}

contract TokenDelegatorTest is Test {
    TokenDelegator public tokenDelegator;
    IMintableERC20 public token;
    address public user;
    address public from;
    address public to; 

    function setUp() public {
        user = address(0xd1405fE8FaEe965075a6F903d773194463da0CfB);
        from = address(0x00000000219ab540356cBB839Cbe05303d7705Fa);
        to = address(0xBE0eB53F46cd790Cd13851d5EFf43D12404d33E8);
        token = IMintableERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        tokenDelegator = new TokenDelegator();
    }

    function testApprove() public {
        vm.prank(from);
        tokenDelegator.approve(user);
        assertEq(tokenDelegator.approvals(user, from), true);
    }

    function testTransferToken() public {
        uint256 transferAmount = 66;
        uint256 initialBalance = token.balanceOf(to);
        vm.prank(from);
        tokenDelegator.approve(user);
        vm.prank(from);
        token.approve(address(tokenDelegator), transferAmount);
        vm.prank(user);
        tokenDelegator.transferToken(token, from, to, transferAmount);
        assertEq(token.balanceOf(to), initialBalance + transferAmount);
    }

    function testTransferWithoutApproval() public {
        uint256 transferAmount = 66;
        vm.expectRevert();
        tokenDelegator.transferToken(token, from, to, transferAmount);
    }

    function testInsufficientBalance() public {
        uint256 transferAmount = token.balanceOf(from) + 1;
        vm.expectRevert();
        tokenDelegator.transferToken(token, from, to, transferAmount);
    }

    function testBatchTransfer() public {
        TokenDelegator.Transfer[] memory transfers = new TokenDelegator.Transfer[](2);
        transfers[0] = TokenDelegator.Transfer(token, from, to, 100);
        transfers[1] = TokenDelegator.Transfer(token, from, to, 200);

        // Setup approvals and token allowances
        vm.prank(from);
        tokenDelegator.approve(user); // from approves user to manage their tokens
        vm.prank(from);
        token.approve(address(tokenDelegator), 300); // from approves TokenDelegator to handle 300 tokens

        uint256 initialBalanceTo = token.balanceOf(to);
        uint256 initialBalanceFrom = token.balanceOf(from);

        // Execute batch transfer
        vm.prank(user);
        tokenDelegator.transferBatch(transfers);

        // Check balances after transfer
        assertEq(token.balanceOf(to), initialBalanceTo + 300); // to should receive 300 tokens total
        assertEq(token.balanceOf(from), initialBalanceFrom - 300); // from should have 300 less tokens
    }

    function testBatchTransferWithoutApproval() public {
        TokenDelegator.Transfer[] memory transfers = new TokenDelegator.Transfer[](2);
        transfers[0] = TokenDelegator.Transfer(token, from, to, 100);
        transfers[1] = TokenDelegator.Transfer(token, from, to, 200);

        // Expecting a revert due to lack of approval
        vm.expectRevert("TokenDelegator: not approved for all tokens");
        vm.prank(user);
        tokenDelegator.transferBatch(transfers);
    }

    function testBatchTransferInsufficientBalance() public {
        TokenDelegator.Transfer[] memory transfers = new TokenDelegator.Transfer[](1);
        transfers[0] = TokenDelegator.Transfer(token, from, to, 1100); // Amount greater than the balance

        // Setup approvals
        vm.prank(from);
        tokenDelegator.approve(user);
        vm.prank(from);
        token.approve(address(tokenDelegator), 1100); // Attempt to approve more than the balance

        // Expecting a revert due to insufficient balance
        vm.expectRevert();
        vm.prank(user);
        tokenDelegator.transferBatch(transfers);
    }
}
