#!/bin/bash

# Install Forge dependencies
forge install

# Print the initial deploying message
echo "Deploying Contracts on Mode..."

source .env

export ETHERSCAN_API_KEY=$MODESCAN_API_KEY
export RPC_URL=$MODE_RPC_URL

read -p "Press enter to begin the deployment..."

forge script script/deploy-migration.s.sol:DeployMigrationScript --rpc-url $RPC_URL --broadcast -vvvv --private-key $PRIVATE_KEY --verify --verifier blockscout --delay 15
