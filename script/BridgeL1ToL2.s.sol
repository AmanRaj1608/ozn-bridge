// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Minimal interface for the L1StandardBridge
interface IStandardBridge {
    function bridgeERC20To(
        address _localToken,
        address _remoteToken,
        address _to,
        uint256 _amount,
        uint32 _minGasLimit,
        bytes calldata _extraData
    ) external payable;
}

contract BridgeL1ToL2 is Script {
    function run() external {
        // --- Configuration ---
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        string memory sepoliaRpcURL = vm.envString("SEPOLIA_RPC_URL");

        // Address of your L1Token token on Sepolia
        address l1TokenAddress = vm.envAddress("L1_TOKEN_ADDRESS");
        require(l1TokenAddress != address(0), "L1_TOKEN_ADDRESS env var must be set.");

        // Address of your L2Token token on Ozean
        address l2TokenAddress = vm.envAddress("L2_TOKEN_ADDRESS");
        require(l2TokenAddress != address(0), "L2_TOKEN_ADDRESS env var must be set.");

        // L1 Standard Bridge address on Sepolia
        address l1StandardBridgeAddr = vm.envAddress("L1_STANDARD_BRIDGE_SEPOLIA");
        if (l1StandardBridgeAddr == address(0)) {
            l1StandardBridgeAddr = 0x8f42BD64b98f35EC696b968e3ad073886464dEC1; // using the proxy one address
        }
        require(l1StandardBridgeAddr != address(0), "L1 Standard Bridge address for Sepolia must be set and valid.");

        // Recipient address on L2 (Ozean). Can be the same as deployer or different.
        address l2Recipient = vm.envAddress("L2_RECIPIENT_ADDRESS");
        if (l2Recipient == address(0)) {
            l2Recipient = vm.addr(deployerPrivateKey);
        }

        // Amount of L1 tokens to bridge (e.g., 100 tokens with 18 decimals)
        uint256 amountToBridge = vm.envUint("BRIDGE_AMOUNT_L1_TO_L2");
        if (amountToBridge == 0) {
            amountToBridge = 1 * (10 ** 18);
        }

        // Min gas limit for the L2 transaction execution
        uint32 minGasLimitL2 = uint32(vm.envUint("L2_MIN_GAS_LIMIT"));
        if (minGasLimitL2 == 0) {
            minGasLimitL2 = 200_000;
        }

        // no extra data for this basic bridge
        bytes memory extraData = "";

        console.log("--- Bridging L1 to L2 ---");
        console.log("L1 RPC URL (Sepolia): %s", sepoliaRpcURL);
        console.log("L1 Token (MyL1ERC20 on Sepolia): %s", l1TokenAddress);
        console.log("L2 Token (MyL2BridgedERC20 on Ozean): %s", l2TokenAddress);
        console.log("L1 Standard Bridge (Sepolia): %s", l1StandardBridgeAddr);
        console.log("L2 Recipient (Ozean): %s", l2Recipient);
        console.log("Amount to Bridge: %s tokens (wei)", amountToBridge);
        console.log("Min Gas Limit for L2 Tx: %s", minGasLimitL2);
        console.log("Broadcasting from address: %s", vm.addr(deployerPrivateKey));

        // --- Execution ---
        vm.startBroadcast(deployerPrivateKey);

        // 1. Approve the L1 Standard Bridge to spend the L1 tokens
        IERC20 l1Token = IERC20(l1TokenAddress);
        uint256 currentAllowance = l1Token.allowance(vm.addr(deployerPrivateKey), l1StandardBridgeAddr);
        if (currentAllowance < amountToBridge) {
            console.log(
                "Current allowance is %s. Approving L1 Standard Bridge for %s tokens...",
                currentAllowance,
                amountToBridge
            );
            l1Token.approve(l1StandardBridgeAddr, type(uint256).max);
            // l1Token.approve(l1StandardBridgeAddr, amountToBridge);
            console.log("Approval transaction sent.");
        } else {
            console.log("Sufficient allowance (%s) already set for L1 Standard Bridge.", currentAllowance);
        }

        // 2. Call bridgeERC20To on the L1 Standard Bridge
        IStandardBridge bridge = IStandardBridge(l1StandardBridgeAddr);
        console.log("Calling bridgeERC20To on L1 Standard Bridge...");

        // msg.value should be 0, op docs -> paid by the relayer
        bridge.bridgeERC20To{value: 0}(
            l1TokenAddress, // _localToken (L1 token)
            l2TokenAddress, // _remoteToken (L2 token)
            l2Recipient, // _to (recipient on L2)
            amountToBridge, // _amount
            minGasLimitL2, // _minGasLimit (for L2 execution)
            extraData // _extraData
        );

        vm.stopBroadcast();
    }
}
