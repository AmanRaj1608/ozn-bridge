// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {L1Token} from "src/L1/L1Token.sol";

contract DeployL1Token is Script {
    string internal constant TOKEN_NAME = "Ozean Token";
    string internal constant TOKEN_SYMBOL = "OZT";
    uint256 internal constant INITIAL_SUPPLY_BASE_UNITS = 1_000_000; // decimals already in L1Token.sol

    function run() external returns (address deployedTokenAddress) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        L1Token token = new L1Token(
            TOKEN_NAME,
            TOKEN_SYMBOL,
            INITIAL_SUPPLY_BASE_UNITS
        );

        deployedTokenAddress = address(token);
        console.log("L1Token deployed to Sepolia at: %s", deployedTokenAddress);
        console.log("Initial supply: %s", INITIAL_SUPPLY_BASE_UNITS);
        console.log(
            "Actual total supply (with decimals): %s",
            token.totalSupply()
        );
        console.log(
            "Deployer (owner) balance: %s",
            token.balanceOf(vm.addr(deployerPrivateKey))
        );

        vm.stopBroadcast();

        return deployedTokenAddress;
    }
}
