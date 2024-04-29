// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol";
import {TokenDelegator} from "src/TokenDelegator.sol";
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

// MockERC20 simulates a basic ERC20 token with minting and burning capabilities.
contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    // Allows the contract owner to mint tokens to a specified address.
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

// TokenDelegatorTest is a set of unit tests for the TokenDelegator contract.
contract TokenDelegatorTest is Test {
    TokenDelegator public tokenDelegator;
    MockERC20 public token;
    address public user;
    address public from;
    address public to;

    // setUp initializes the test environment.
    function setUp() public {
        user = vm.addr(1); // Simulated user address
        from = vm.addr(2); // Simulated sender address
        to = vm.addr(3);   // Simulated receiver address
        token = new MockERC20("Test Token", "TTN"); // Create a new token instance
        tokenDelegator = new TokenDelegator(ISwapRouter(address(0))); // Create a new TokenDelegator instance

        token.mint(from, 1000); // Mint 1000 tokens to the 'from' address for testing
    }

    // testApprove verifies that approvals can be correctly set and queried.
    function testApprove() public {
        vm.prank(from);
        tokenDelegator.approve(user);
        assertEq(tokenDelegator.allowance(user, from), true, "User should be approved.");
    }

    // testTransferToken checks the functionality of transferring tokens through the delegator.
    function testTransferToken() public {
        uint256 transferAmount = 66;
        uint256 initialBalance = token.balanceOf(to);
        vm.prank(from);
        tokenDelegator.approve(user); // Approve the user to act on behalf of 'from'
        vm.prank(from);
        token.approve(address(tokenDelegator), transferAmount); // Approve token transfer
        vm.prank(user);
        tokenDelegator.transferToken(token, from, to, transferAmount); // Execute transfer
        assertEq(token.balanceOf(to), initialBalance + transferAmount, "Tokens should be transferred.");
    }

    // testTransferWithoutApproval checks that a transfer fails if no approval is given.
    function testTransferWithoutApproval() public {
        uint256 transferAmount = 66;
        vm.expectRevert("TokenDelegator: not approved");
        tokenDelegator.transferToken(token, from, to, transferAmount);
    }

    // testInsufficientBalance checks that a transfer fails if the balance is too low.
    function testInsufficientBalance() public {
        vm.prank(from);
        tokenDelegator.approve(user);
        uint256 transferAmount = token.balanceOf(from) + 1; // Request more tokens than available
        vm.prank(from);
        token.approve(address(tokenDelegator), transferAmount);
        vm.prank(user);
        vm.expectRevert();
        tokenDelegator.transferToken(token, from, to, transferAmount);
    }

    // testBatchTransfer tests the functionality of transferring multiple token batches.
    function testBatchTransfer() public {
        TokenDelegator.Transfer[] memory transfers = new TokenDelegator.Transfer[](2);
        transfers[0] = TokenDelegator.Transfer(token, from, to, 100);
        transfers[1] = TokenDelegator.Transfer(token, from, to, 200);

        vm.prank(from);
        tokenDelegator.approve(user); // Approve user
        vm.prank(from);
        token.approve(address(tokenDelegator), 300); // Approve token transfer

        uint256 initialBalanceTo = token.balanceOf(to);
        uint256 initialBalanceFrom = token.balanceOf(from);

        vm.prank(user);
        tokenDelegator.transferBatch(transfers); // Execute batch transfer

        assertEq(token.balanceOf(to), initialBalanceTo + 300, "Total tokens should be transferred.");
        assertEq(token.balanceOf(from), initialBalanceFrom - 300, "Total tokens should be deducted.");
    }

    // testBatchTransferWithoutApproval checks that batch transfers fail without proper approvals.
    function testBatchTransferWithoutApproval() public {
        TokenDelegator.Transfer[] memory transfers = new TokenDelegator.Transfer[](2);
        transfers[0] = TokenDelegator.Transfer(token, from, to, 100);
        transfers[1] = TokenDelegator.Transfer(token, from, to, 200);

        vm.expectRevert("TokenDelegator: not approved for all tokens");
        vm.prank(user);
        tokenDelegator.transferBatch(transfers);
    }

    // testBatchTransferInsufficientBalance tests batch transfers fail with insufficient balances.
    function testBatchTransferInsufficientBalance() public {
        TokenDelegator.Transfer[] memory transfers = new TokenDelegator.Transfer[](1);
        transfers[0] = TokenDelegator.Transfer(token, from, to, 1001); // Exceed available balance

        vm.prank(from);
        tokenDelegator.approve(user);
        vm.prank(from);
        token.approve(address(tokenDelegator), 1001);

        vm.prank(user);
        vm.expectRevert();
        tokenDelegator.transferBatch(transfers);
    }
}
