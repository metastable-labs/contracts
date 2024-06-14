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
    address public mockUniswapRouter = makeAddr("UniswapV2Router");
    uint256 public marketCapThreshold = 1_000_000_000;
    uint256 public platfromFeePercentage = 10 * 1e18;

    function setUp() public {
        erc20Impl = new LaunchboxERC20();
        curveImpl = new LaunchboxExchange();
        launchpad = new LaunchboxFactory(address(erc20Impl), address(curveImpl), mockUniswapRouter, platfromFeePercentage, marketCapThreshold);
    }
}
