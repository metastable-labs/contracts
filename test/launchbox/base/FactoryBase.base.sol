pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {LaunchboxERC20} from "../../../src/launchbox/token/LaunchboxERC20.sol";
import {LaunchboxERC20Factory} from "../../../src/launchbox/token/LaunchboxERC20Factory.sol";
import {MockRemoteERC20} from "../../../src/migration/mocks/MockRemoteERC20.sol";

contract FactoryBase is Test {
    LaunchboxERC20Factory public factory;
    LaunchboxERC20 public implementation;

    MockRemoteERC20 public remote;

    function setUp() public {
        implementation = new LaunchboxERC20();
        remote = new MockRemoteERC20();
        factory = new LaunchboxERC20Factory(address(implementation));
    }
}
