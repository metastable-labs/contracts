// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";

abstract contract BaseScript is Script {
    constructor() {
        if (block.chainid == 31_337) {
            currentChain = Chains.Localnet;
        } else if (block.chainid == 8453) {
            currentChain = Chains.Base;
        } else if (block.chainid == 84_532) {
            currentChain = Chains.BaseSepolia;
        } else {
            revert("Unsupported chain for deployment");
        }
    }

    Chains currentChain;

    enum Chains {
        Localnet,
        Base,
        BaseSepolia
    }

    function getDeployConfigJson() internal view returns (string memory json) {
        if (currentChain == Chains.Base) {
            json = vm.readFile(string.concat(vm.projectRoot(), "/deployConfigs/base.json"));
        } else if (currentChain == Chains.BaseSepolia) {
            json = vm.readFile(string.concat(vm.projectRoot(), "/deployConfigs/sepolia.base.json"));
        } else {
            json = vm.readFile(string.concat(vm.projectRoot(), "/deployConfigs/localnet.json"));
        }
    }
}
