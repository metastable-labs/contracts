pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {SuperMigrateERC20} from "../../src/migration/SuperMigrateERC20.sol";
import {MockRemoteERC20} from "../../src/migration/mocks/MockRemoteERC20.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

contract SuperERC20Base is Test {
    SuperMigrateERC20 public clone;
    SuperMigrateERC20 public implementation;

    // addresses
    address public bridge = makeAddr("bridge");
    address public nonBridge = makeAddr("nonBridge");
    MockRemoteERC20 public remoteToken;

    string public tokenName = "BeSuper";
    string public tokenSymbol = "BeSuper";
    uint8 tokenDecimal = 18;
    string public currentVersion = "1.0.0";

    function setUp() public {
        // deploy remote token
        remoteToken = new MockRemoteERC20();

        // deploy implementation
        implementation = new SuperMigrateERC20();

        // create clone
        clone = SuperMigrateERC20(Clones.clone(address(implementation)));
    }

    modifier initializeSuperERC20() {
        clone.initialize(bridge, address(remoteToken), tokenName, tokenSymbol, tokenDecimal);
        _;
    }
}
