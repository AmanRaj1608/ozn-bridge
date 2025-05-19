// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {L1Token} from "src/L1/L1Token.sol";

contract L1TokenTest is Test {
    L1Token internal token;
    address internal owner;
    address internal user1;
    address internal user2;
    uint256 internal initialSupply = 1_000_000 * 10 ** 18;

    string internal constant TOKEN_NAME = "Ozean L1 Token";
    string internal constant TOKEN_SYMBOL = "OZN";

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function setUp() public {
        owner = address(this);
        vm.startPrank(owner);
        token = new L1Token(TOKEN_NAME, TOKEN_SYMBOL, 1_000_000);
        vm.stopPrank();

        user1 = vm.addr(1);
        user2 = vm.addr(2);

        // setting diff owner for testing
        owner = vm.addr(0xBEEF);
        vm.startPrank(address(this));
        token.transferOwnership(owner);
        vm.stopPrank();

        // fund user1
        vm.startPrank(address(this));
        token.transfer(user1, 1000 * 10 ** 18);
        vm.stopPrank();
    }

    function test_InitialState() public view {
        assertEq(token.name(), TOKEN_NAME, "Token name mismatch");
        assertEq(token.symbol(), TOKEN_SYMBOL, "Token symbol mismatch");
        assertEq(token.decimals(), 18, "Token decimals mismatch");
        assertEq(token.totalSupply(), initialSupply, "Total supply mismatch");
        assertEq(
            token.balanceOf(address(this)),
            initialSupply - (1000 * 10 ** 18),
            "Deployer initial balance mismatch"
        );
        assertEq(token.owner(), owner, "Owner mismatch");
    }

    function test_Mint() public {
        vm.startPrank(owner);
        uint256 mintAmount = 500 * 10 ** 18;
        token.mint(user2, mintAmount);
        vm.stopPrank();

        assertEq(
            token.balanceOf(user2),
            mintAmount,
            "User2 balance after mint mismatch"
        );
        assertEq(
            token.totalSupply(),
            initialSupply + mintAmount,
            "Total supply after mint mismatch"
        );
    }

    function testFail_MintNotOwner() public {
        vm.startPrank(user1);
        token.mint(user2, 100 * 10 ** 18);
        vm.stopPrank();
    }

    function test_Transfer() public {
        uint256 transferAmount = 100 * 10 ** 18;
        vm.startPrank(user1);

        vm.expectEmit(true, true, true, true);
        emit Transfer(user1, user2, transferAmount);
        token.transfer(user2, transferAmount);
        vm.stopPrank();

        assertEq(
            token.balanceOf(user1),
            (1000 - 100) * 10 ** 18,
            "User1 balance after transfer mismatch"
        );
        assertEq(
            token.balanceOf(user2),
            transferAmount,
            "User2 balance after transfer mismatch"
        );
    }

    function testFail_TransferInsufficientBalance() public {
        vm.startPrank(user2);
        token.transfer(user1, 10 * 10 ** 18);
        vm.stopPrank();
    }

    function test_ApproveAndTransferFrom() public {
        uint256 approveAmount = 200 * 10 ** 18;
        uint256 transferAmount = 150 * 10 ** 18;

        // user1 approves user2 to spend 'approveAmount'
        vm.startPrank(user1);
        vm.expectEmit(true, true, true, true);
        emit Approval(user1, user2, approveAmount);
        token.approve(user2, approveAmount);
        vm.stopPrank();

        assertEq(
            token.allowance(user1, user2),
            approveAmount,
            "Allowance mismatch"
        );

        // user2 transfers 'transferAmount' from user1 to themselves
        vm.startPrank(user2);
        vm.expectEmit(true, true, true, true);
        emit Transfer(user1, user2, transferAmount);
        token.transferFrom(user1, user2, transferAmount);
        vm.stopPrank();

        assertEq(
            token.balanceOf(user1),
            (1000 - 150) * 10 ** 18,
            "User1 balance after transferFrom mismatch"
        );
        assertEq(
            token.balanceOf(user2),
            transferAmount,
            "User2 balance after transferFrom mismatch"
        );
        assertEq(
            token.allowance(user1, user2),
            approveAmount - transferAmount,
            "Allowance after transferFrom mismatch"
        );
    }

    function testFail_TransferFromInsufficientAllowance() public {
        uint256 transferAmount = 50 * 10 ** 18;
        // user1 has not approved user2
        vm.startPrank(user2);
        token.transferFrom(user1, user2, transferAmount);
        vm.stopPrank();
    }

    function testFail_TransferFromInsufficientBalance() public {
        uint256 approveAmount = 2000 * 10 ** 18;
        uint256 transferAmount = 1500 * 10 ** 18;

        vm.startPrank(user1);
        token.approve(user2, approveAmount);
        vm.stopPrank();

        vm.startPrank(user2);
        token.transferFrom(user1, user2, transferAmount);
        vm.stopPrank();
    }

    // Test transfer to address(0)
    function testFail_TransferToZeroAddress() public {
        vm.startPrank(user1);
        token.transfer(address(0), 10 * 10 ** 18);
        vm.stopPrank();
    }

    // Test transferFrom to address(0)
    function testFail_TransferFromToZeroAddress() public {
        uint256 approveAmount = 100 * 10 ** 18;
        vm.startPrank(user1);
        token.approve(user2, approveAmount);
        vm.stopPrank();

        vm.startPrank(user2);
        token.transferFrom(user1, address(0), 50 * 10 ** 18);
        vm.stopPrank();
    }
}
