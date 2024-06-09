// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../src/launchbox/token/LaunchboxERC20.sol";
import "../src/launchbox/token/LaunchboxERC20Factory.sol";
import {Script} from "forge-std/Script.sol";

contract DeployLaunchboxScript is Script {
    function run() external returns (address implementation, address factory) {
        // get pvt key from env file, log associated address
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(privateKey);
        // deploy implementation
        implementation = address(new LaunchboxERC20());

        // deploy factory
        factory = address(new LaunchboxERC20Factory(address(implementation)));

        vm.stopBroadcast();

        return (implementation, factory);
    }
}
