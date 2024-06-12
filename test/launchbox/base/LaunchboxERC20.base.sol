pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {LaunchboxERC20} from "../../../src/launchbox/token/LaunchboxERC20.sol";
import {MockRemoteERC20} from "../../../src/migration/mocks/MockRemoteERC20.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

contract LaunchboxERC20Base is Test {
    LaunchboxERC20 public clone;
    LaunchboxERC20 public implementation;

    // addresses
    address public bridge = makeAddr("bridge");
    MockRemoteERC20 public remoteToken;

    string public tokenName = "Launchbox";
    string public tokenSymbol = "Launchbox";
    uint8 tokenDecimal = 18;
    string public currentVersion = "1.0.0";

    function setUp() public {
        // deploy remote token
        remoteToken = new MockRemoteERC20();

        // deploy implementation
        implementation = new LaunchboxERC20();

        // create clone
        clone = LaunchboxERC20(Clones.clone(address(implementation)));
    }

    modifier initializeSuperERC20() {
        clone.initialize();
        _;
    }
}
