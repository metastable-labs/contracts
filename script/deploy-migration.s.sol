// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../src/migration/SuperMigrateERC20.sol";
import "../src/migration/factory/SuperERC20Factory.sol";
import {Script} from "forge-std/Script.sol";

contract DeployMigrationScript is Script {
    function run() external returns (address implementation, address factory) {
        // get pvt key from env file, log associated address
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address L2BridgeAddress = vm.envAddress("L2_BRIDGE_ADDRESS");

        vm.startBroadcast(privateKey);
        // deploy implementation
        implementation = address(new SuperMigrateERC20());

        // deploy factory
        factory = address(new SuperERC20Factory(address(implementation), L2BridgeAddress));

        vm.stopBroadcast();

        return (implementation, factory);
    }
}
