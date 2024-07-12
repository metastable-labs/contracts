pragma solidity ^0.8.20;

import {LaunchboxFactoryBase} from "../base/LaunchboxFactory.base.sol";
import {LaunchboxFactory} from "../../src/launchbox/token/LaunchboxFactory.sol";
import {LaunchboxERC20} from "../../src/launchbox/token/LaunchboxERC20.sol";
import {LaunchboxExchange} from "../../src/launchbox/exchange/LaunchboxExchange.sol";

// do fork testing
// forge test --mc _Fork --fork-url https://base-rpc.publicnode.com
contract LaunchboxFactoryUnit_Fork is LaunchboxFactoryBase {
    function test_DeployWithInvalidToken() public {
        vm.expectRevert(LaunchboxFactory.EmptyTokenImplementation.selector);
        LaunchboxFactory testLaunchpad = new LaunchboxFactory(
            address(0),
            address(curveImpl),
            mockAerodromeRouter,
            platformFeeReceiver,
            marketCapThreshold,
            0,
            platfromFeePercentage,
            communityPercentage
        );
    }

    function test_DeployWithInvalidLaunchboxExchange() public {
        vm.expectRevert(LaunchboxFactory.EmptyLaunchboxExchangeImplementation.selector);
        LaunchboxFactory testLaunchpad = new LaunchboxFactory(
            address(erc20Impl),
            address(0),
            mockAerodromeRouter,
            platformFeeReceiver,
            marketCapThreshold,
            0,
            platfromFeePercentage,
            communityPercentage
        );
    }

    function test_DeployWithInvalidRouter() public {
        vm.expectRevert(LaunchboxFactory.EmptyAerodromeRouter.selector);
        LaunchboxFactory testLaunchpad = new LaunchboxFactory(
            address(erc20Impl),
            address(curveImpl),
            address(0),
            platformFeeReceiver,
            marketCapThreshold,
            0,
            platfromFeePercentage,
            communityPercentage
        );
    }

    function test_DeployWithInvalidPlatformFeeReceiver() public {
        vm.expectRevert(LaunchboxFactory.EmptyPlatformFeeReceiver.selector);
        LaunchboxFactory testLaunchpad = new LaunchboxFactory(
            address(erc20Impl),
            address(curveImpl),
            mockAerodromeRouter,
            address(0),
            marketCapThreshold,
            0,
            platfromFeePercentage,
            communityPercentage
        );
    }

    function test_DeployWithGreaterThan100Fee() public {
        vm.expectRevert(LaunchboxFactory.FeeGreaterThanHundred.selector);
        LaunchboxFactory testLaunchpad = new LaunchboxFactory(
            address(erc20Impl),
            address(curveImpl),
            mockAerodromeRouter,
            platformFeeReceiver,
            marketCapThreshold,
            0,
            100 * 1e18,
            1 * 1e18
        );
    }

    function test_onlyOwnerCanSetNewMarketCap() public {
        vm.startPrank(makeAddr("Unkown"));
        vm.expectRevert();
        launchpad.setMarketCapThreshold(10);
        vm.stopPrank();

        launchpad.setMarketCapThreshold(10);
        assertEq(10, launchpad.marketCapThreshold());
    }

    function test_deployTokens() public {
        (address tokenContract, address curveContract) = launchpad.deployToken("TEST", "TEST", "ipfs://", 100);
        assertEq(LaunchboxERC20(tokenContract).totalSupply(), 100);
        assertEq(LaunchboxExchange(payable(curveContract)).saleActive(), true);
        assertEq(LaunchboxERC20(tokenContract).balanceOf(curveContract), 90);
        assertEq(LaunchboxERC20(tokenContract).balanceOf(platformFeeReceiver), 1);
        assertEq(LaunchboxERC20(tokenContract).balanceOf(address(this)), 9);
    }

    function test_revert_renounceOwnership() public {
        vm.expectRevert();
        launchpad.renounceOwnership();
    }

    function test_setPlatformFee() public {
        launchpad.setPlatformFeePercentage(1);
        assertEq(launchpad.platformFeePercentage(), 1);
    }

    function test_revert_setPlatformFeeNonOwner() public {
        vm.prank(makeAddr("unknown"));
        vm.expectRevert();
        launchpad.setPlatformFeePercentage(1);
        assertEq(launchpad.platformFeePercentage(), platfromFeePercentage);
    }

    function test_setCommunityFee() public {
        launchpad.setCommunityPercentage(1);
        assertEq(launchpad.communityPercentage(), 1);
    }

    function test_revert_setCommunityFeeNonOwner() public {
        vm.prank(makeAddr("unknown"));
        vm.expectRevert();
        launchpad.setCommunityPercentage(1);
        assertEq(launchpad.communityPercentage(), communityPercentage);
    }

    function test_setTradeFee() public {
        launchpad.setTradeFee(1);
        assertEq(launchpad.tradeFee(), 1);
    }

    function test_revert_setTradeFeeNonOwner() public {
        vm.prank(makeAddr("unknown"));
        vm.expectRevert();
        launchpad.setTradeFee(1);
        assertEq(launchpad.tradeFee(), tradeFee);
    }

    function test_setPlatformFeeReceiver() public {
        launchpad.setPlatformFeeAddress(payable(makeAddr("newPlatformFeeReceiver")));
        assertEq(launchpad.platformFeeAddress(), makeAddr("newPlatformFeeReceiver"));
    }

    function test_revert_setPlatformFeeReceiverNonOwner() public {
        vm.prank(makeAddr("unknown"));
        vm.expectRevert();
        launchpad.setPlatformFeeAddress(payable(makeAddr("newPlatformFeeReceiver")));
        assertEq(launchpad.platformFeeAddress(), platformFeeReceiver);
    }

    function test_revert_setPlatformFeeReceiverAsZero() public {
        vm.expectRevert(LaunchboxFactory.EmptyPlatformFeeReceiver.selector);
        launchpad.setPlatformFeeAddress(payable(address(0)));
        assertEq(launchpad.platformFeeAddress(), platformFeeReceiver);
    }
}
