// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol";
import {TokenDelegator, IUniswapV2Router} from "src/TokenDelegator.sol";

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
    IUniswapV2Router public uniswapV2Router;

    function setUp() public {
        user = vm.addr(1);
        from = vm.addr(2);
        to = vm.addr(3);
        token = new MockERC20("Test Token", "TTN");
        token2 = new MockERC20("Test Token2", "TTN");
        tokenDelegator = new TokenDelegator();
        uniswapV2Router = IUniswapV2Router(
            0x87aE49902B749588c15c5FE2A6fE6a1067a5bea0
        );
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

    // function testAddActionStoresCorrectly() public {
    //     uint amountIn = 100e18;
    //     uint timeZero = block.timestamp + 1 days; // Set timeZero to a future time
    //     uint duration = 1 days;
    //     bool isActive = true;
    //     uint expectedId = 1;

    //     tokenDelegator.addAction(
    //         expectedId,
    //         token,
    //         token2,
    //         amountIn,
    //         from,
    //         to,
    //         timeZero,
    //         duration,
    //         isActive
    //     );

    //     TokenDelegator.AutomationsAction memory storedAction = tokenDelegator
    //         .getAutomationAction(expectedId);

    //     assertEq(
    //         storedAction.ownerAddress,
    //         address(this),
    //         "Owner address does not match"
    //     );
    //     assertEq(storedAction.initialized, true, "Initialized should be true");
    //     assertEq(storedAction.duration, duration, "Duration does not match");
    //     assertEq(storedAction.timeZero, timeZero, "TimeZero does not match");
    //     assertEq(
    //         address(storedAction.tokenIn),
    //         address(token),
    //         "TokenIn does not match"
    //     );
    //     assertEq(
    //         address(storedAction.tokenOut),
    //         address(token2),
    //         "TokenOut does not match"
    //     );
    //     assertEq(storedAction.amountIn, amountIn, "AmountIn does not match");
    //     assertEq(storedAction.from, from, "From address does not match");
    //     assertEq(storedAction.to, to, "To address does not match");
    //     assertEq(storedAction.isActive, isActive, "IsActive does not match");
    // }

    // function testGetAutomationAction() public {
    //     uint amountIn = 500e18;
    //     uint timeZero = block.timestamp + 1 days; // Set timeZero to a future time
    //     uint duration = 1 days;
    //     bool isActive = true;
    //     uint id = 1;

    //     token.approve(address(tokenDelegator), 500 ether);
    //     token2.approve(address(tokenDelegator), 500 ether);

    //     tokenDelegator.addAction(
    //         id,
    //         token,
    //         token2,
    //         amountIn,
    //         from,
    //         to,
    //         timeZero,
    //         duration,
    //         isActive
    //     );

    //     TokenDelegator.AutomationsAction memory action = tokenDelegator
    //         .getAutomationAction(id);

    //     assertEq(
    //         action.ownerAddress,
    //         address(this),
    //         "Owner address does not match"
    //     );
    //     assertEq(action.initialized, true, "Initialized should be true");
    //     assertEq(action.duration, duration, "Duration does not match");
    //     assertEq(action.timeZero, timeZero, "TimeZero does not match");
    //     assertEq(
    //         address(action.tokenIn),
    //         address(token),
    //         "TokenIn does not match"
    //     );
    //     assertEq(
    //         address(action.tokenOut),
    //         address(token2),
    //         "TokenOut does not match"
    //     );
    //     assertEq(action.amountIn, amountIn, "AmountIn does not match");
    //     assertEq(action.from, from, "From address does not match");
    //     assertEq(action.to, to, "To address does not match");
    //     assertEq(action.isActive, isActive, "IsActive does not match");
    // }

    // function testSetAutomationActiveState() public {
    //     uint amountIn = 500e18;
    //     uint timeZero = block.timestamp + 1 days; // Set timeZero to a future time
    //     uint duration = 1 days;
    //     bool isActive = true;
    //     uint id = 1;

    //     tokenDelegator.addAction(
    //         id,
    //         token,
    //         token2,
    //         amountIn,
    //         from,
    //         to,
    //         timeZero,
    //         duration,
    //         isActive
    //     );

    //     vm.prank(address(this));
    //     tokenDelegator.setAutomationActiveState(id, false);

    //     TokenDelegator.AutomationsAction memory storedAction = tokenDelegator
    //         .getAutomationAction(id);

    //     assertEq(storedAction.isActive, false, "IsActive should be false");

    //     vm.prank(address(this));
    //     tokenDelegator.setAutomationActiveState(id, true);

    //     storedAction = tokenDelegator.getAutomationAction(id);

    //     assertEq(storedAction.isActive, true, "IsActive should be true");
    // }

    // function testGetAmountsOut() public {
    //     uint amountIn = 500e18;

    //     token.mint(from, 1000 ether);
    //     token2.mint(address(this), 1000 ether);

    //     address[] memory path = new address[](2);
    //     path[0] = address(token);
    //     path[1] = address(token2);

    //     console.log("Calling getAmountsOut");

    //     uint[] memory amounts;
    //     try uniswapV2Router.getAmountsOut(amountIn, path) returns (
    //         uint[] memory _amounts
    //     ) {
    //         amounts = _amounts;
    //         console.log("getAmountsOut succeeded");
    //         console.log("Amounts out:", amounts[0], amounts[1]);
    //     } catch {
    //         console.log("getAmountsOut failed");
    //     }
    // }

    // function testExecuteAction() public {
    //     uint amountIn = 500e18;
    //     uint timeZero = block.timestamp + 1 days;
    //     uint duration = 1 days;
    //     bool isActive = true;
    //     uint id = 1;

    //     token.mint(from, 1000 ether);
    //     token.approve(address(tokenDelegator), 500 ether);
    //     token2.approve(address(tokenDelegator), 500 ether);
    //     vm.prank(from);
    //     token.approve(address(tokenDelegator), 500 ether);

    //     tokenDelegator.addAction(
    //         id,
    //         token,
    //         token2,
    //         amountIn,
    //         from,
    //         to,
    //         timeZero,
    //         duration,
    //         isActive
    //     );

    //     TokenDelegator.AutomationsAction memory action = tokenDelegator
    //         .getAutomationAction(id);

    //     assertEq(
    //         action.timeZero,
    //         timeZero,
    //         "TimeZero should be defined correctly"
    //     );

    //     vm.warp(block.timestamp + 2 days);

    //     vm.prank(address(this));
    //     tokenDelegator.executeAction();

    //     action = tokenDelegator.getAutomationAction(id);
    //     console.log(
    //         "After executeAction: timeZero:",
    //         action.timeZero,
    //         "currentTime:",
    //         block.timestamp
    //     );

    //     assertEq(
    //         action.timeZero,
    //         timeZero + 1 days,
    //         "TimeZero should be updated after executing action"
    //     );
    // }

    // function testFailExecuteActionInsufficientAllowance() public {
    //     uint amountIn = 500e18;
    //     uint timeZero = block.timestamp + 1 days;
    //     uint duration = 1 days;
    //     bool isActive = true;
    //     uint id = 1;

    //     token.mint(from, 1000 ether);
    //     token.approve(address(tokenDelegator), 500 ether);
    //     token2.approve(address(tokenDelegator), 500 ether);
    //     vm.prank(from);
    //     token.approve(address(tokenDelegator), 100 ether);

    //     tokenDelegator.addAction(
    //         id,
    //         token,
    //         token2,
    //         amountIn,
    //         from,
    //         to,
    //         timeZero,
    //         duration,
    //         isActive
    //     );

    //     vm.warp(block.timestamp + 2 days);

    //     vm.prank(address(this));
    //     tokenDelegator.executeAction();
    // }
}
