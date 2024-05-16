// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol";
import {TokenDelegator} from "src/TokenDelegator.sol";

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
    MockERC20 public token2;
    address public user;
    address public from;
    address public to;

    // setUp initializes the test environment.
    function setUp() public {
        user = vm.addr(1); // Simulated user address
        from = vm.addr(2); // Simulated sender address
        to = vm.addr(3); // Simulated receiver address
        token = new MockERC20("Test Token", "TTN"); // Create a new token instance
        token2 = new MockERC20("Test Token2", "TTN"); // Create a second new token instance
        tokenDelegator = new TokenDelegator(); // Create a new TokenDelegator instance

        token.mint(from, 1000); // Mint 1000 tokens to the 'from' address for testing
    }

    // testApprove verifies that approvals can be correctly set and queried.
    function testApprove() public {
        vm.prank(from);
        tokenDelegator.approve(user);
        assertEq(
            tokenDelegator.allowance(user, from),
            true,
            "User should be approved."
        );
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
        assertEq(
            token.balanceOf(to),
            initialBalance + transferAmount,
            "Tokens should be transferred."
        );
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
        TokenDelegator.Transfer[]
            memory transfers = new TokenDelegator.Transfer[](2);
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

        assertEq(
            token.balanceOf(to),
            initialBalanceTo + 300,
            "Total tokens should be transferred."
        );
        assertEq(
            token.balanceOf(from),
            initialBalanceFrom - 300,
            "Total tokens should be deducted."
        );
    }

    // testBatchTransferWithoutApproval checks that batch transfers fail without proper approvals.
    function testBatchTransferWithoutApproval() public {
        TokenDelegator.Transfer[]
            memory transfers = new TokenDelegator.Transfer[](2);
        transfers[0] = TokenDelegator.Transfer(token, from, to, 100);
        transfers[1] = TokenDelegator.Transfer(token, from, to, 200);

        vm.expectRevert("TokenDelegator: not approved for all tokens");
        vm.prank(user);
        tokenDelegator.transferBatch(transfers);
    }

    // testBatchTransferInsufficientBalance tests batch transfers fail with insufficient balances.
    function testBatchTransferInsufficientBalance() public {
        TokenDelegator.Transfer[]
            memory transfers = new TokenDelegator.Transfer[](1);
        transfers[0] = TokenDelegator.Transfer(token, from, to, 1001); // Exceed available balance

        vm.prank(from);
        tokenDelegator.approve(user);
        vm.prank(from);
        token.approve(address(tokenDelegator), 1001);

        vm.prank(user);
        vm.expectRevert();
        tokenDelegator.transferBatch(transfers);
    }

    function testAddActionIncrementsId() public {
        uint initialId = tokenDelegator.nextAutomationActionId();
        tokenDelegator.addAction(
            token,
            token2,
            100e18,
            50e18,
            user,
            user,
            block.timestamp + 1 days,
            1
        );
        uint newId = tokenDelegator.nextAutomationActionId();
        assertEq(
            newId,
            initialId + 1,
            "nextAutomationActionId should increment by 1"
        );
    }

    function testAddActionStoresCorrectly() public {
        uint amountIn = 100e18;
        uint amountOutMin = 50e18;
        uint deadline = block.timestamp + 1 days;
        uint delayDays = 1;

        // Expected ID for the new action
        uint expectedId = tokenDelegator.nextAutomationActionId();

        // Call addAction
        tokenDelegator.addAction(
            token,
            token2,
            amountIn,
            amountOutMin,
            from,
            to,
            deadline,
            delayDays
        );

        // Fetch the stored action directly using the public getter for the mapping
        (
            uint delay,
            uint date,
            IERC20 tokenIn,
            IERC20 tokenOut,
            uint inAmount,
            uint outMin,
            address fromAddr,
            address toAddr,
            uint dl
        ) = tokenDelegator.actions(expectedId);

        // Assert all fields
        assertEq(address(tokenIn), address(token), "TokenIn does not match");
        assertEq(address(tokenOut), address(token2), "TokenOut does not match");
        assertEq(inAmount, amountIn, "AmountIn does not match");
        assertEq(outMin, amountOutMin, "AmountOutMin does not match");
        assertEq(fromAddr, from, "From address does not match");
        assertEq(toAddr, to, "To address does not match");
        assertEq(dl, deadline, "Deadline does not match");
        assertEq(delay, delayDays * 1 days, "Delay does not match");
        assertEq(date, 0, "Date should be 0");
    }

    function testGetAutomationAction() public {
        // Add an action to test retrieval
        token.approve(address(tokenDelegator), 500 ether);
        token2.approve(address(tokenDelegator), 500 ether);

        uint id = tokenDelegator.addAction(
            token,
            token2,
            500 ether,
            250 ether,
            address(this),
            address(this),
            block.timestamp + 1 days,
            1
        );

        // Retrieve the action
        TokenDelegator.AutomationsAction memory retrievedAction = tokenDelegator
            .getAutomationAction(id);

        // Assertions to verify that the retrieved action matches the added action
        assertEq(
            address(retrievedAction.tokenIn),
            address(token),
            "TokenIn does not match"
        );
        assertEq(
            address(retrievedAction.tokenOut),
            address(token2),
            "TokenOut does not match"
        );
        assertEq(
            retrievedAction.amountIn,
            500 ether,
            "AmountIn does not match"
        );
        assertEq(
            retrievedAction.amountOutMin,
            250 ether,
            "AmountOutMin does not match"
        );
        assertEq(
            retrievedAction.from,
            address(this),
            "From address does not match"
        );
        assertEq(
            retrievedAction.to,
            address(this),
            "To address does not match"
        );
        assertEq(
            retrievedAction.deadline,
            block.timestamp + 1 days,
            "Deadline does not match"
        );
        assertEq(retrievedAction.delay, 1 days, "Delay does not match");
    }

    // Add a test for invalid ID retrieval
    function testFailGetAutomationActionInvalidId() public view {
        tokenDelegator.getAutomationAction(999); // This ID should not exist
    }
}
