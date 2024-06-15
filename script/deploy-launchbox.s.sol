// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../src/launchbox/token/LaunchboxERC20.sol";
import "../src/launchbox/token/LaunchboxFactory.sol";
import {BaseScript, stdJson, console2} from "./base.s.sol";

contract DeployLaunchboxScript is BaseScript {
    using stdJson for string;

    function run() external returns (address implementation, address factory) {
        // get pvt key from env file, log associated address
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(privateKey);

        string memory deployConfigJson = getDeployConfigJson();

        address router = deployConfigJson.readAddress(".aerodromeRouter");
        address platformFeeReceiver = deployConfigJson.readAddress(".platformFeeReceiver");
        uint256 marketCapThreshold = deployConfigJson.readUint(".marketCapThreshold");
        uint256 platformFeePercentage = deployConfigJson.readUint(".platformFeePercentage");
        uint256 communityPercentage = deployConfigJson.readUint(".communityPercentage");
        // deploy implementation
        address tokenImplementation = address(new LaunchboxERC20());
        // deploy exchange contract
        address exchangeImplementation = address(new LaunchboxExchange());

        // deploy factory
        factory = address(
            new LaunchboxFactory(
                tokenImplementation,
                exchangeImplementation,
                router,
                platformFeeReceiver,
                marketCapThreshold,
                platformFeePercentage,
                communityPercentage
            )
        );

        vm.stopBroadcast();

        return (tokenImplementation, factory);
    }
}
