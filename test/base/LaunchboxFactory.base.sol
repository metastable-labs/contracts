// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {LaunchboxFactory} from "../../src/launchbox/token/LaunchboxFactory.sol";
import {LaunchboxERC20} from "../../src/launchbox/token/LaunchboxERC20.sol";
import {LaunchboxExchange} from "../../src/launchbox/exchange/LaunchboxExchange.sol";

contract LaunchboxFactoryBase is Test {
    LaunchboxFactory public launchpad;
    LaunchboxERC20 public erc20Impl;
    LaunchboxExchange public curveImpl;
    address public mockAerodromeRouter = 0xcF77a3Ba9A5CA399B7c97c74d54e5b1Beb874E43;
    address public platformFeeReceiver = makeAddr("PlatformFeeReceiver");
    uint256 public marketCapThreshold = 1_000_000_000;
    uint256 public platfromFeePercentage = 1 * 1e18;
    uint256 public communityPercentage = 9 * 1e18;
    uint256 public tradeFee = 1 * 1e17;

    function setUp() public {
        erc20Impl = new LaunchboxERC20();
        curveImpl = new LaunchboxExchange();
        launchpad = new LaunchboxFactory(
            address(erc20Impl),
            address(curveImpl),
            mockAerodromeRouter,
            platformFeeReceiver,
            marketCapThreshold,
            tradeFee,
            platfromFeePercentage,
            communityPercentage
        );
    }
}
