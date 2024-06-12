pragma solidity 0.8.20;

import {FactoryBase, LaunchboxERC20, LaunchboxERC20Factory} from "../base/FactoryBase.base.sol";

contract FactoryUnitTest is FactoryBase {
    string constant tokenName = "Launchbox";
    string constant tokenSymbol = "Launchbox";
    uint8 tokenDecimal = 18;
    uint256 totalSupply = 10_000_000_000;
    string public currentVersion = "1.0.0";

    function test_LaunchboxCreate() public {
        // deploy new token
        LaunchboxERC20 newToken = LaunchboxERC20(factory.createToken(tokenName, tokenSymbol, tokenDecimal, totalSupply));

        // assert data
        assertEq(newToken.name(), tokenName);
        assertEq(newToken.symbol(), tokenSymbol);
        assertEq(newToken.decimals(), tokenDecimal);
        assertEq(newToken.totalSupply(), totalSupply);
    }
}
