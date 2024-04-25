#!/bin/bash

# Install Forge dependencies
forge install

# Print the initial deploying message
echo "Deploying Contracts on Optimism..."

source .env

export ETHERSCAN_API_KEY=$OPTIMISTICSCAN_API_KEY
export RPC_URL=$OPTIMISM_RPC_URL

read -p "Press enter to begin the deployment..."

forge script script/deploy-migration.s.sol:DeployMigrationScript --rpc-url $RPC_URL --broadcast -vvvv --private-key $PRIVATE_KEY --verify --delay 15