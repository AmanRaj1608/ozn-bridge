// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {L2Token} from "src/L2/L2Token.sol";
import {IOptimismMintableERC20} from "src/L2/IOptimismMintableERC20.sol";

contract L2TokenTest is Test {
    L2Token internal token;
    address internal l2BridgeMock;
    address internal l1TokenMock;
    address internal user1;
    address internal otherAddress;

    string internal constant TOKEN_NAME = "Ozean L2 Token";
    string internal constant TOKEN_SYMBOL = "OZN";

    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        l2BridgeMock = vm.addr(0xBEEF); // mock l2 bridge address
        l1TokenMock = vm.addr(0xCAFE); // mock l1 token address
        user1 = vm.addr(1);
        otherAddress = vm.addr(2);

        // deploy the l2 token
        token = new L2Token(
            l2BridgeMock,
            l1TokenMock,
            TOKEN_NAME,
            TOKEN_SYMBOL
        );
    }

    function test_InitialState() public view {
        assertEq(token.name(), TOKEN_NAME, "Token name mismatch");
        assertEq(token.symbol(), TOKEN_SYMBOL, "Token symbol mismatch");
        assertEq(token.decimals(), 18, "Token decimals mismatch");
        assertEq(token.totalSupply(), 0, "Initial total supply should be 0");
        assertEq(token.l1Token(), l1TokenMock, "L1 token address mismatch");
        assertEq(token.l2Bridge(), l2BridgeMock, "L2 bridge address mismatch");
    }

    function test_Mint_ByL2Bridge() public {
        uint256 mintAmount = 1000 * 10 ** 18;
        vm.startPrank(l2BridgeMock);

        vm.expectEmit(true, true, true, true); // from, to, value
        emit Transfer(address(0), user1, mintAmount); // Mint event
        token.mint(user1, mintAmount);
        vm.stopPrank();

        assertEq(
            token.balanceOf(user1),
            mintAmount,
            "User1 balance after mint mismatch"
        );
        assertEq(
            token.totalSupply(),
            mintAmount,
            "Total supply after mint mismatch"
        );
    }

    function testFail_Mint_NotByL2Bridge() public {
        vm.startPrank(otherAddress); // not the l2 bridge
        token.mint(user1, 100 * 10 ** 18);
        vm.stopPrank();
    }

    function test_Burn_ByL2Bridge() public {
        uint256 initialMintAmount = 500 * 10 ** 18;
        uint256 burnAmount = 200 * 10 ** 18;

        // first, mint some tokens to user1 by the bridge
        vm.startPrank(l2BridgeMock);
        token.mint(user1, initialMintAmount);
        vm.stopPrank();

        assertEq(
            token.balanceOf(user1),
            initialMintAmount,
            "User1 balance before burn incorrect"
        );

        // now, burn some tokens from user1, initiated by the bridge
        vm.startPrank(l2BridgeMock);
        vm.expectEmit(true, true, true, true); // from, to, value
        emit Transfer(user1, address(0), burnAmount); // Burn event
        token.burn(user1, burnAmount);
        vm.stopPrank();

        assertEq(
            token.balanceOf(user1),
            initialMintAmount - burnAmount,
            "User1 balance after burn mismatch"
        );
        assertEq(
            token.totalSupply(),
            initialMintAmount - burnAmount,
            "Total supply after burn mismatch"
        );
    }

    function testFail_Burn_NotByL2Bridge() public {
        uint256 initialMintAmount = 500 * 10 ** 18;
        // mint some tokens first
        vm.startPrank(l2BridgeMock);
        token.mint(user1, initialMintAmount);
        vm.stopPrank();

        vm.startPrank(otherAddress); // not the l2 bridge
        token.burn(user1, 100 * 10 ** 18);
        vm.stopPrank();
    }

    function testFail_Burn_InsufficientBalance() public {
        uint256 burnAmount = 100 * 10 ** 18;
        // user1 has 0 balance

        vm.startPrank(l2BridgeMock);
        token.burn(user1, burnAmount);
        vm.stopPrank();
    }
}
