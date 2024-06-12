pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {SuperERC20Factory} from "../../../src/migration/factory/SuperERC20Factory.sol";
import {MockRemoteERC20} from "../../../src/migration/mocks/MockRemoteERC20.sol";
import {SuperMigrateERC20} from "../../../src/migration/SuperMigrateERC20.sol";

contract FactoryBase is Test {
    SuperERC20Factory public factory;
    SuperMigrateERC20 public implementation;

    address public bridge = makeAddr("bridge");
    MockRemoteERC20 public remote;

    function setUp() public {
        implementation = new SuperMigrateERC20();
        remote = new MockRemoteERC20();
        factory = new SuperERC20Factory(address(implementation), bridge);
    }
}
