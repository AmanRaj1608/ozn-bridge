// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Minimal interface for the L2StandardBridge
interface IL2StandardBridge {
    function withdrawTo(address _l2Token, address _to, uint256 _amount, uint32 _minGasLimit, bytes calldata _extraData)
        external
        payable;
}

contract BridgeL2ToL1 is Script {
    function run() external {
        // --- Configuration ---
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        string memory ozeanRpcURL = vm.envString("OZEAN_RPC_URL");
        if (bytes(ozeanRpcURL).length == 0) {
            ozeanRpcURL = "https://poseidon-testnet.rpc.caldera.xyz/http";
        }

        // Address of your L2 token on Ozean
        address l2TokenAddress = vm.envAddress("L2_TOKEN_ADDRESS");
        require(l2TokenAddress != address(0), "L2_TOKEN_ADDRESS env var must be set.");

        // L2 Standard Bridge address on Ozean
        address l2StandardBridgeAddr = vm.envAddress("L2_STANDARD_BRIDGE_OZEAN");
        if (l2StandardBridgeAddr == address(0)) {
            l2StandardBridgeAddr = 0x4200000000000000000000000000000000000010;
        }
        require(l2StandardBridgeAddr != address(0), "L2 Standard Bridge address for Ozean must be set and valid.");

        // Recipient address on L1 (Sepolia). Can be the same as deployer or different.
        address l1Recipient = vm.envAddress("L1_RECIPIENT_ADDRESS");
        if (l1Recipient == address(0)) {
            l1Recipient = vm.addr(deployerPrivateKey);
        }

        // Amount of L2 tokens to bridge back to L1
        uint256 amountToBridge = vm.envUint("BRIDGE_AMOUNT_L2_TO_L1");
        if (amountToBridge == 0) {
            amountToBridge = 1 * (10 ** 18);
        }

        // Min gas limit for the L1 transaction execution
        uint32 minGasLimitL1 = uint32(vm.envUint("L1_MIN_GAS_LIMIT"));
        if (minGasLimitL1 == 0) {
            minGasLimitL1 = 200_000;
        }

        // no extra data for this basic bridge
        bytes memory extraData = "";

        console.log("--- Bridging L2 to L1 ---");
        console.log("L2 RPC URL (Ozean): %s", ozeanRpcURL);
        console.log("L2 Token on Ozean: %s", l2TokenAddress);
        console.log("L2 Standard Bridge (Ozean): %s", l2StandardBridgeAddr);
        console.log("L1 Recipient (Sepolia): %s", l1Recipient);
        console.log("Amount to Bridge: %s tokens (wei)", amountToBridge);
        console.log("Min Gas Limit for L1 Tx: %s", minGasLimitL1);
        console.log("Broadcasting from address: %s", vm.addr(deployerPrivateKey));

        // --- Execution ---
        vm.startBroadcast(deployerPrivateKey);

        // 1. Approve the L2 Standard Bridge to spend the L2 tokens
        IERC20 l2Token = IERC20(l2TokenAddress);
        uint256 currentAllowance = l2Token.allowance(vm.addr(deployerPrivateKey), l2StandardBridgeAddr);
        if (currentAllowance < amountToBridge) {
            console.log(
                "Current allowance is %s. Approving L2 Standard Bridge for %s tokens...",
                currentAllowance,
                amountToBridge
            );
            l2Token.approve(l2StandardBridgeAddr, type(uint256).max);
            console.log("Approval transaction sent.");
        } else {
            console.log("Sufficient allowance (%s) already set for L2 Standard Bridge.", currentAllowance);
        }

        // 2. Call withdrawTo on the L2 Standard Bridge
        IL2StandardBridge bridge = IL2StandardBridge(l2StandardBridgeAddr);
        console.log("Calling withdrawTo on L2 Standard Bridge...");

        // For ERC20 withdrawals, this is typically 0 value
        // The OP Stack may charge an L2 fee for the withdrawal
        bridge.withdrawTo{value: 0}(
            l2TokenAddress, // _l2Token
            l1Recipient, // _to (recipient on L1)
            amountToBridge, // _amount
            minGasLimitL1, // _minGasLimit (for L1 execution)
            extraData // _extraData
        );

        vm.stopBroadcast();
    }
}
