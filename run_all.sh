#!/bin/bash
set -e

# Colors for terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Ozean Token Bridge Project ===${NC}"
echo "This script will build the project, run tests, deploy tokens, and handle bridging operations."

# Step 1: Build the project
echo -e "\n${GREEN}=== Building Project ===${NC}"
forge build

# Step 2: Run tests
echo -e "\n${GREEN}=== Running Tests ===${NC}"
forge test

# Check if an operation was specified
if [ $# -eq 0 ]; then
    echo -e "\n${YELLOW}Please specify an operation:${NC}"
    echo "  deploy-l1     - Deploy the L1 token on Sepolia"
    echo "  deploy-l2     - Deploy the L2 token on Ozean"
    echo "  bridge-l1-l2  - Bridge tokens from L1 to L2"
    echo "  bridge-l2-l1  - Bridge tokens from L2 to L1"
    echo "  deploy-all    - Deploy both tokens and setup"
    echo "  bridge-all    - Run both bridging operations"
    echo "  all           - Run everything in sequence"
    exit 0
fi

# Function to check if env variable is set, with default value option
check_env() {
    local var_name=$1
    local default_value=$2
    
    if [ -z "${!var_name}" ]; then
        if [ -n "$default_value" ]; then
            export "$var_name"="$default_value"
            echo -e "${YELLOW}WARNING: $var_name not set, using default: $default_value${NC}"
        else
            echo -e "${RED}ERROR: $var_name environment variable is not set!${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}$var_name is set to: ${!var_name}${NC}"
    fi
}

# Check critical environment variables
check_env "PRIVATE_KEY" ""
check_env "SEPOLIA_RPC_URL" ""

# Functions for each operation
deploy_l1_token() {
    echo -e "\n${GREEN}=== Deploying L1 Token on Sepolia ===${NC}"
    check_env "SEPOLIA_ETHERSCAN_API_KEY" ""
    
    # Deploy L1 token with verification
    forge script script/L1/DeployL1Token.s.sol:DeployL1Token \
        --rpc-url $SEPOLIA_RPC_URL \
        --broadcast \
        --verify \
        -vvvv
    
    # Extract the L1 token address from the broadcast output
    L1_TOKEN_ADDRESS=$(grep -A 1 "L1Token deployed to Sepolia at:" broadcast/DeployL1Token.s.sol/**/run-latest.json | tail -n 1 | sed 's/.*"contractAddress": "\(.*\)",/\1/')
    
    if [ -n "$L1_TOKEN_ADDRESS" ]; then
        echo -e "${GREEN}L1 Token deployed at: $L1_TOKEN_ADDRESS${NC}"
        export L1_TOKEN_ADDRESS="$L1_TOKEN_ADDRESS"
    else
        echo -e "${RED}Failed to extract L1 token address from deployment output${NC}"
        exit 1
    fi
}

deploy_l2_token() {
    echo -e "\n${GREEN}=== Deploying L2 Token on Ozean ===${NC}"
    check_env "L1_TOKEN_ADDRESS" ""
    check_env "L2_STANDARD_BRIDGE_OZEAN" "0x4200000000000000000000000000000000000010"
    
    # Deploy L2 token
    forge script script/L2/DeployL2Token.s.sol:DeployL2Token \
        --rpc-url https://poseidon-testnet.rpc.caldera.xyz/http \
        --broadcast \
        -vvvv
    
    # Extract L2 token address
    L2_TOKEN_ADDRESS=$(grep -A 1 "L2Token deployed to Ozean at:" broadcast/DeployL2Token.s.sol/**/run-latest.json | tail -n 1 | sed 's/.*"contractAddress": "\(.*\)",/\1/')
    
    if [ -n "$L2_TOKEN_ADDRESS" ]; then
        echo -e "${GREEN}L2 Token deployed at: $L2_TOKEN_ADDRESS${NC}"
        export L2_TOKEN_ADDRESS="$L2_TOKEN_ADDRESS"
    else
        echo -e "${RED}Failed to extract L2 token address from deployment output${NC}"
        exit 1
    fi
}

bridge_l1_to_l2() {
    echo -e "\n${GREEN}=== Bridging Tokens from L1 (Sepolia) to L2 (Ozean) ===${NC}"
    check_env "L1_TOKEN_ADDRESS" ""
    check_env "L2_TOKEN_ADDRESS" ""
    check_env "L1_STANDARD_BRIDGE_SEPOLIA" "0x8f42BD64b98f35EC696b968e3ad073886464dEC1"
    check_env "BRIDGE_AMOUNT_L1_TO_L2" "10000000000000000000" # 10 tokens with 18 decimals
    
    # Bridge tokens from L1 to L2
    forge script script/BridgeL1ToL2.s.sol:BridgeL1ToL2 \
        --rpc-url $SEPOLIA_RPC_URL \
        --broadcast \
        -vvvv
        
    echo -e "${YELLOW}Note: It may take a few minutes for the tokens to appear on Ozean (L2).${NC}"
    echo -e "${YELLOW}Check the transaction on Ozean Explorer: https://poseidon-testnet.explorer.caldera.xyz/address/$(grep -oP '(?<=L2 Recipient \(Ozean\): ).*' broadcast/BridgeL1ToL2.s.sol/**/run-latest.json | head -n 1)${NC}"
}

bridge_l2_to_l1() {
    echo -e "\n${GREEN}=== Bridging Tokens from L2 (Ozean) to L1 (Sepolia) ===${NC}"
    check_env "L2_TOKEN_ADDRESS" ""
    check_env "L2_STANDARD_BRIDGE_OZEAN" "0x4200000000000000000000000000000000000010"
    check_env "BRIDGE_AMOUNT_L2_TO_L1" "5000000000000000000" # 5 tokens with 18 decimals
    
    # Bridge tokens from L2 to L1
    forge script script/BridgeL2ToL1.s.sol:BridgeL2ToL1 \
        --rpc-url https://poseidon-testnet.rpc.caldera.xyz/http \
        --broadcast \
        -vvvv
        
    echo -e "${YELLOW}Note: It may take several hours for the tokens to appear on Sepolia (L1) due to the challenge period.${NC}"
    echo -e "${YELLOW}Check the transaction on Sepolia Explorer: https://sepolia.etherscan.io/address/$(grep -oP '(?<=L1 Recipient \(Sepolia\): ).*' broadcast/BridgeL2ToL1.s.sol/**/run-latest.json | head -n 1)${NC}"
}

# Execute based on the specified operation
case "$1" in
    deploy-l1)
        deploy_l1_token
        ;;
    deploy-l2)
        deploy_l2_token
        ;;
    bridge-l1-l2)
        bridge_l1_to_l2
        ;;
    bridge-l2-l1)
        bridge_l2_to_l1
        ;;
    deploy-all)
        deploy_l1_token
        deploy_l2_token
        ;;
    bridge-all)
        bridge_l1_to_l2
        bridge_l2_to_l1
        ;;
    all)
        deploy_l1_token
        deploy_l2_token
        bridge_l1_to_l2
        bridge_l2_to_l1
        ;;
    *)
        echo -e "${RED}Invalid operation: $1${NC}"
        exit 1
        ;;
esac

echo -e "\n${GREEN}=== Operation(s) Completed ===${NC}" 