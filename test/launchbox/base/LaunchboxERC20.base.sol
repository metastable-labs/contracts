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

    string public tokenName = "Launchbox";
    string public tokenSymbol = "Launchbox";
    uint8 tokenDecimal = 18;
    uint256 totalSupply = 10_000_000_000;
    uint256 tokenSupplyAfterFee = 9_000_000_000;
    uint256 feeFromTokenSupply = 1_000_000_000;
    string public currentVersion = "1.0.0";
    address exchangeContract = 0xF175520C52418dfE19C8098071a252da48Cd1C19;
    address platformFeeAddress = 0xF175520C52418dfE19C8098071a252da48Cd1C19;

    function setUp() public {
        // deploy implementation
        implementation = new LaunchboxERC20();

        // create clone
        clone = LaunchboxERC20(Clones.clone(address(implementation)));
    }

    modifier initializeSuperERC20() {
        clone.initialize(
            tokenName,
            tokenSymbol,
            tokenDecimal,
            tokenSupplyAfterFee,
            feeFromTokenSupply,
            exchangeContract,
            platformFeeAddress
        );
        _;
    }
}
