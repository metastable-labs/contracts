pragma solidity 0.8.20;

import {FactoryBase, SuperMigrateERC20, SuperERC20Factory} from "../base/FactoryBase.base.sol";

contract FactoryUnitTest is FactoryBase {
    string constant tokenName = "BeSuper";
    string constant tokenSymbol = "BB";
    uint8 tokenDecimal = 18;

    function test_BeSuper() public {
        // prepare args
        address remoteToken = address(remote);

        // deploy new token
        SuperMigrateERC20 newToken =
            SuperMigrateERC20(factory.beSuper(remoteToken, tokenName, tokenSymbol, tokenDecimal));

        // assert data
        assertEq(newToken.name(), tokenName);
        assertEq(newToken.symbol(), tokenSymbol);
        assertEq(newToken.decimals(), tokenDecimal);
        assertEq(newToken.BRIDGE(), bridge);
        assertEq(newToken.l1Token(), remoteToken);
    }

    function test_revert_CannotBeSuperWithZeroAddress() public {
        // prepare args
        address remoteToken = address(0);

        // expect revert when Remote token address is zero address
        vm.expectRevert(SuperERC20Factory.RemoteTokenCannotBeZeroAddress.selector);
        factory.beSuper(remoteToken, tokenName, tokenSymbol, tokenDecimal);
    }
}