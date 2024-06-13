pragma solidity ^0.8.20;

import {LaunchboxFactoryBase} from "../base/LaunchboxFactory.base.sol";
import {LaunchboxFactory} from "../../src/launchbox/token/LaunchboxFactory.sol";
import {LaunchboxERC20} from "../../src/launchbox/token/LaunchboxERC20.sol";
import {LaunchboxExchange} from "../../src/launchbox/exchange/LaunchboxExchange.sol";

contract LaunchboxFactoryUnit is LaunchboxFactoryBase {
    function test_DeployWithInvalidToken() public {
        vm.expectRevert(LaunchboxFactory.EmptyTokenImplementation.selector);
        LaunchboxFactory testLaunchpad = new LaunchboxFactory(address(0), address(curveImpl), mockUniswapRouter);
    }

    function test_DeployWithInvalidLaunchboxExchange() public {
        vm.expectRevert(LaunchboxFactory.EmptyLaunchboxExchangeImplementation.selector);
        LaunchboxFactory testLaunchpad = new LaunchboxFactory(address(erc20Impl), address(0), mockUniswapRouter);
    }

    function test_DeployWithInvalidRouter() public {
        vm.expectRevert(LaunchboxFactory.EmptyUniswapRouter.selector);
        LaunchboxFactory testLaunchpad = new LaunchboxFactory(address(erc20Impl), address(curveImpl), address(0));
    }

    function test_newTokemImplCannotBeZero() public {
        vm.expectRevert(LaunchboxFactory.EmptyTokenImplementation.selector);
        launchpad.setTokemImplementation(address(0));
    }

    function test_newLaunchboxExchangeImplCannotBeZero() public {
        vm.expectRevert(LaunchboxFactory.EmptyLaunchboxExchangeImplementation.selector);
        launchpad.setLaunchboxExchangeImplementation(address(0));
    }

    function test_newRouterCannotBeZero() public {
        vm.expectRevert(LaunchboxFactory.EmptyUniswapRouter.selector);
        launchpad.setRouter(address(0));
    }

    function test_onlyOwnerCanSetNewAddress() public {
        vm.startPrank(makeAddr("Unkown"));
        vm.expectRevert();
        launchpad.setLaunchboxExchangeImplementation(address(1));

        vm.expectRevert();
        launchpad.setTokemImplementation(address(1));

        vm.expectRevert();
        launchpad.setRouter(address(1));
        vm.stopPrank();

        launchpad.setLaunchboxExchangeImplementation(address(1));
        assertEq(address(1), launchpad.launchboxExchangeImplementation());

        launchpad.setTokemImplementation(address(1));
        assertEq(address(1), launchpad.tokenImplementation());

        launchpad.setRouter(address(1));
        assertEq(address(1), launchpad.uniswapRouter());
    }

    function test_deployTokens() public {
        (address tokenContract, address curveContract) = launchpad.deployToken("TEST", "TEST", 100, "ipfs://", 100);
        assertEq(LaunchboxERC20(tokenContract).totalSupply(), 100);
        assertEq(LaunchboxExchange(payable(curveContract)).saleActive(), true);
        assertEq(LaunchboxERC20(tokenContract).balanceOf(curveContract), 100);
    }
}