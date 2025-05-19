# Ozean Token Bridge

A Foundry repository for creating an ERC20 token on ETH Sepolia and a bridged representation of it on the Ozean testnet using the OP standard bridge.

## Overview

This project demonstrates the process of:

1. Deploying an ERC20 token on Ethereum Sepolia (L1)
2. Deploying its bridged representation on Ozean testnet (L2)
3. Bridging tokens between L1 and L2 in both directions

There appears to be an issue with the Ozean Poseidon testnet sequencer not processing L1->L2 bridge transactions. See my [Bug Analysis](./report.md) for details.

## Deployed Contracts

### Sepolia (L1)

- L1 Token (OZT): `0x52523f748F96C10FafbF58Ce8201d251674613cE`
- L1 Standard Bridge: `0x8f42BD64b98f35EC696b968e3ad073886464dEC1`
- L1 to L2 Bridge Transaction(L1ChugSplashProxy::fallback -> L1StandardBridge::bridgeERC20To): [Sepolia Etherscan](https://sepolia.etherscan.io/tx/0x0d3d18a468a6d1ac23f148779152eb11852ad691f72ccf426199847c62c3e3c0/advanced#eventlog)
- Explorer: [Sepolia Etherscan](https://sepolia.etherscan.io/address/0x52523f748F96C10FafbF58Ce8201d251674613cE)

### Ozean (L2)

- L2 Token (OZT-L2): `0x52523f748F96C10FafbF58Ce8201d251674613cE`
- L2 Standard Bridge: `0x4200000000000000000000000000000000000010`
- Explorer: [Ozean Explorer](https://poseidon-testnet.explorer.caldera.xyz/address/0x52523f748F96C10FafbF58Ce8201d251674613cE/)

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- Sepolia ETH for gas
- Sepolia Etherscan API key (for verification)

## Environment Setup

Create a `.env` file in the project root with the following variables:

```shell
# Required
PRIVATE_KEY=""
SEPOLIA_RPC_URL=https://eth-sepolia.public.blastapi.io

# For verification
SEPOLIA_ETHERSCAN_API_KEY="etherscan_api_key"

# Addresses (will be set by scripts if not provided)
L1_TOKEN_ADDRESS=0x52523f748F96C10FafbF58Ce8201d251674613cE
L2_TOKEN_ADDRESS=0x52523f748F96C10FafbF58Ce8201d251674613cE

# Bridge addresses (defaults are provided in scripts)
L1_STANDARD_BRIDGE_SEPOLIA=0x8f42BD64b98f35EC696b968e3ad073886464dEC1
L2_STANDARD_BRIDGE_OZEAN=0x4200000000000000000000000000000000000010

# Optional
L1_RECIPIENT_ADDRESS=0x00000050FdBAbEB90FC6ED9891716300Ff8F53cb
L2_RECIPIENT_ADDRESS=0x00000050FdBAbEB90FC6ED9891716300Ff8F53cb
BRIDGE_AMOUNT_L1_TO_L2=1000000000000000000
BRIDGE_AMOUNT_L2_TO_L1=1000000000000000000
```

## Project Structure

```
├── script/
│   ├── L1/
│   │   └── DeployL1Token.s.sol    # L1 token deployment script
│   ├── L2/
│   │   └── DeployL2Token.s.sol    # L2 token deployment script
│   ├── BridgeL1ToL2.s.sol         # L1 to L2 bridging script
│   └── BridgeL2ToL1.s.sol         # L2 to L1 bridging script
├── src/
│   ├── L1/
│   │   └── L1Token.sol            # L1 ERC20 token contract
│   └── L2/
│       ├── L2Token.sol            # L2 bridged token contract
│       └── IOptimismMintableERC20.sol # Interface for L2 token
├── bug_report.md                  # Documentation of the L1->L2 sequencer issue
├── run_all.sh                     # Comprehensive shell script
├── script.sh                      # Simple script for basic operations
└── foundry.toml                   # Foundry configuration
```

## Usage

### Manual Operations

For manual operations, you can use the individual Foundry scripts:

#### Build the project

```shell
forge build
```

#### Run tests

```shell
forge test
```

#### Deploy L1 Token (Sepolia)

```shell
forge script script/L1/DeployL1Token.s.sol:DeployL1Token --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv
```

#### Deploy L2 Token (Ozean)

```shell
forge script script/L2/DeployL2Token.s.sol:DeployL2Token --rpc-url https://poseidon-testnet.rpc.caldera.xyz/http --broadcast -vvvv
```

#### Bridge L1 to L2

```shell
forge script script/BridgeL1ToL2.s.sol:BridgeL1ToL2 --rpc-url https://eth-sepolia.public.blastapi.io --broadcast -vvvv
```

#### Bridge L2 to L1

```shell
forge script script/BridgeL2ToL1.s.sol:BridgeL2ToL1 --rpc-url https://poseidon-testnet.rpc.caldera.xyz/http --broadcast -vvvv
```

### Using the Comprehensive Script

The `run_all.sh` script provides a streamlined way to perform all operations:

```shell
chmod +x run_all.sh # Make script executable
./run_all.sh deploy-l1 # Deploy L1 token
./run_all.sh deploy-l2 # Deploy L2 token
./run_all.sh bridge-l1-l2 # Bridge tokens from L1 to L2
./run_all.sh bridge-l2-l1 # Bridge tokens from L2 to L1
./run_all.sh deploy-all # Deploy both tokens
./run_all.sh bridge-all # Bridge both tokens
# Run all operations in sequence
./run_all.sh all
```

## Troubleshooting

### L1 to L2 Transaction Issues

The L1 to L2 transaction isn't appearing on the Ozean explorer after a successful L1 transaction:

The Ozean Poseidon testnet sequencer appears to not be processing incoming L1 to L2 messages properly.
From the OP Stack documentation:

> "Transfers from Ethereum to OP Mainnet via the Standard Bridge are usually completed within 1-3 minutes."
> However, even after 24+ hours, L1 to L2 transactions have not been processed on the Ozean testnet.

### L2 to L1 Transaction Issues

L2 to L1 transactions involve a challenge period (typically 7 days for mainnet, possibly shorter for testnets):

1. Initiate the withdrawal on L2
2. Wait for the challenge period to complete
3. Claim your funds on L1

## Resources

- [Ozean Documentation](https://docs.ozean.finance/)
- [OP Standard Bridge Documentation](https://docs.optimism.io/app-developers/bridging/standard-bridge/)
