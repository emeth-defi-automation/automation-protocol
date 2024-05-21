// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol";
import {TokenDelegator} from "src/TokenDelegator.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract TokenDelegatorTest is Test {
    TokenDelegator public tokenDelegator;
    MockERC20 public token;
    MockERC20 public token2;
    address public user;
    address public from;
    address public to;

    function setUp() public {
        user = vm.addr(1);
        from = vm.addr(2);
        to = vm.addr(3);
        token = new MockERC20("Test Token", "TTN");
        token2 = new MockERC20("Test Token2", "TTN");
        tokenDelegator = new TokenDelegator();

        token.mint(from, 1000);
    }

    function testApprove() public {
        vm.prank(from);
        tokenDelegator.approve(user);
        assertEq(
            tokenDelegator.allowance(user, from),
            true,
            "User should be approved."
        );
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
        assertEq(
            token.balanceOf(to),
            initialBalance + transferAmount,
            "Tokens should be transferred."
        );
    }

    function testTransferWithoutApproval() public {
        uint256 transferAmount = 66;
        vm.expectRevert("TokenDelegator: not approved");
        tokenDelegator.transferToken(token, from, to, transferAmount);
    }

    function testInsufficientBalance() public {
        vm.prank(from);
        tokenDelegator.approve(user);
        uint256 transferAmount = token.balanceOf(from) + 1;
        vm.prank(from);
        token.approve(address(tokenDelegator), transferAmount);
        vm.prank(user);
        vm.expectRevert();
        tokenDelegator.transferToken(token, from, to, transferAmount);
    }

    function testBatchTransfer() public {
        TokenDelegator.Transfer[]
            memory transfers = new TokenDelegator.Transfer[](2);
        transfers[0] = TokenDelegator.Transfer(token, from, to, 100);
        transfers[1] = TokenDelegator.Transfer(token, from, to, 200);

        vm.prank(from);
        tokenDelegator.approve(user);
        vm.prank(from);
        token.approve(address(tokenDelegator), 300);

        uint256 initialBalanceTo = token.balanceOf(to);
        uint256 initialBalanceFrom = token.balanceOf(from);

        vm.prank(user);
        tokenDelegator.transferBatch(transfers);
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

    function testBatchTransferWithoutApproval() public {
        TokenDelegator.Transfer[]
            memory transfers = new TokenDelegator.Transfer[](2);
        transfers[0] = TokenDelegator.Transfer(token, from, to, 100);
        transfers[1] = TokenDelegator.Transfer(token, from, to, 200);

        vm.expectRevert("TokenDelegator: not approved for all tokens");
        vm.prank(user);
        tokenDelegator.transferBatch(transfers);
    }

    function testBatchTransferInsufficientBalance() public {
        TokenDelegator.Transfer[]
            memory transfers = new TokenDelegator.Transfer[](1);
        transfers[0] = TokenDelegator.Transfer(token, from, to, 1001);

        vm.prank(from);
        tokenDelegator.approve(user);
        vm.prank(from);
        token.approve(address(tokenDelegator), 1001);

        vm.prank(user);
        vm.expectRevert();
        tokenDelegator.transferBatch(transfers);
    }

    // function testAddActionIncrementsId() public {
    //     uint initialId = tokenDelegator.nextAutomationActionId();
    //     uint newActionId = initialId; // Assuming front-end or another mechanism assigns this ID
    //     tokenDelegator.addAction(
    //         newActionId,
    //         token,
    //         token2,
    //         100e18,
    //         user,
    //         user,
    //         block.timestamp + 1 days,
    //         1
    //     );
    //     uint newId = tokenDelegator.nextAutomationActionId();
    //     assertEq(
    //         newId,
    //         initialId + 1,
    //         "nextAutomationActionId should increment by 1"
    //     );
    // }

    function testAddActionStoresCorrectly() public {
        uint amountIn = 100e18;
        uint deadline = block.timestamp + 1 days;
        uint delayDays = 1;
        uint expectedId = tokenDelegator.nextAutomationActionId();

        tokenDelegator.addAction(
            expectedId,
            token,
            token2,
            amountIn,
            from,
            to,
            deadline,
            delayDays
        );

        (
            bool initialized,
            uint delay,
            uint date,
            IERC20 tokenIn,
            IERC20 tokenOut,
            uint inAmount,
            address fromAddr,
            address toAddr,
            uint dl
        ) = tokenDelegator.actions(expectedId);

        assertEq(address(tokenIn), address(token), "TokenIn does not match");
        assertEq(address(tokenOut), address(token2), "TokenOut does not match");
        assertEq(amountIn, inAmount, "AmountIn does not match");
        assertEq(from, fromAddr, "From address does not match");
        assertEq(to, toAddr, "To address does not match");
        assertEq(deadline, dl, "Deadline does not match");
        assertEq(delay, delayDays * 1 days, "Delay does not match");
        assertEq(date, 0, "Date should be 0");
        assertEq(initialized, true, "Initialized should be true");
    }

    function testGetAutomationAction() public {
        token.approve(address(tokenDelegator), 500 ether);
        token2.approve(address(tokenDelegator), 500 ether);

        uint id = tokenDelegator.nextAutomationActionId();
        tokenDelegator.addAction(
            id,
            token,
            token2,
            500 ether,
            from,
            to,
            block.timestamp + 1 days,
            1
        );

        (
            bool initialized,
            uint delay,
            uint date,
            IERC20 tokenIn,
            IERC20 tokenOut,
            uint amountIn,
            address fromAddr,
            address toAddr,
            uint dl
        ) = tokenDelegator.actions(id);

        assertEq(address(tokenIn), address(token), "TokenIn does not match");
        assertEq(address(tokenOut), address(token2), "TokenOut does not match");
        assertEq(amountIn, 500 ether, "AmountIn does not match");
        assertEq(fromAddr, from, "From address does not match");
        assertEq(toAddr, to, "To address does not match");
        assertEq(date, 0, "Deadline does not match");
        assertEq(delay, 1 days, "Delay does not match");
        assertEq(initialized, true, "initialized should be true");
        assertEq(dl, block.timestamp + 1 days, "Deadline does not match");
    }

    function testFailGetAutomationActionInvalidId() public view {
        tokenDelegator.getAutomationAction(999);
    }
}
