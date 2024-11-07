#!/bin/bash

# Install Forge dependencies
forge install

# Print the initial deploying message
echo "Deploying Contracts on Ink..."

source .env

export ETHERSCAN_API_KEY=$BASESCAN_API_KEY
export RPC_URL=$INKONCHAIN_RPC_URL

read -p "Press enter to begin the deployment..."

forge script script/deploy-migration.s.sol:DeployMigrationScript --rpc-url $RPC_URL --broadcast -vvvv --private-key $PRIVATE_KEY --verify --delay 15
