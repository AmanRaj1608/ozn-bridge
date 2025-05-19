// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {L2Token} from "src/L2/L2Token.sol";

contract DeployL2Token is Script {
    string internal constant TOKEN_NAME_L2 = "Ozean Token (L2)";
    string internal constant TOKEN_SYMBOL_L2 = "OZT-L2";

    function run() external returns (address deployedL2TokenAddress) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        console.log("Deployer address: %s", deployerAddress);

        // Required: Address of the L1 ERC20 token deployed on Sepolia
        address l1TokenAddress = vm.envAddress("L1_TOKEN_ADDRESS");
        require(
            l1TokenAddress != address(0),
            "L1_TOKEN_ADDRESS environment variable must be set."
        );
        console.log(
            "Using L1 Token Address (L1_TOKEN_ADDRESS): %s",
            l1TokenAddress
        );

        // L2 Standard Bridge address for Ozean - https://docs.ozean.finance/developer-documentation/contract-addresses
        address l2StandardBridgeAddress = vm.envAddress(
            "L2_STANDARD_BRIDGE_OZEAN"
        );
        if (l2StandardBridgeAddress == address(0)) {
            l2StandardBridgeAddress = 0x4200000000000000000000000000000000000010; // default OP Stack L2StandardBridge
        }
        require(
            l2StandardBridgeAddress != address(0),
            "L2 Standard Bridge address for Ozean must be set and valid."
        );
        console.log("L2 Standard Bridge: %s", l2StandardBridgeAddress);

        vm.startBroadcast(deployerPrivateKey);

        L2Token l2Token = new L2Token(
            l2StandardBridgeAddress,
            l1TokenAddress,
            TOKEN_NAME_L2,
            TOKEN_SYMBOL_L2
        );

        deployedL2TokenAddress = address(l2Token);
        console.log("L2Token deployed to Ozean at: %s", deployedL2TokenAddress);
        console.log("  L1 Token: %s", l2Token.l1Token());
        console.log("  L2 Bridge: %s", l2Token.l2Bridge());
        console.log("  Name: %s", l2Token.name());
        console.log("  Symbol: %s", l2Token.symbol());

        vm.stopBroadcast();

        return deployedL2TokenAddress;
    }
}
