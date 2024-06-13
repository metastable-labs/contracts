pragma solidity ^0.8.20;

import {LaunchboxERC20Base} from "../base/LaunchboxERC20.base.sol";
import {LaunchboxFactory} from "../../src/launchbox/token/LaunchboxFactory.sol";
import {LaunchboxERC20} from "../../src/launchbox/token/LaunchboxERC20.sol";
import {LaunchboxExchange} from "../../src/launchbox/exchange/LaunchboxExchange.sol";

contract LaunchboxERC20Unit is LaunchboxERC20Base {
    string public name = "ERC20";
    string public symbol = "ERC20_SYMBOL";
    uint256 public maxSupply = 1_000_000e18;
    uint256 public marketCapThreshold = 100_000e18;
    string public metadataUri = "ipfs://metadata";
    address public router = makeAddr("UniswapRouter");
    function test_initialize() public {
        assertEq(erc20.launchboxExchange(), address(0));
        erc20.initialize(name, symbol, maxSupply, marketCapThreshold, metadataUri, exchangeImplementation, router);
        assertNotEq(erc20.launchboxExchange(), address(0));
        assertEq(erc20.name(), name);
        assertEq(erc20.symbol(), symbol);
        assertEq(erc20.metadataURI(), metadataUri);
        assertEq(address(LaunchboxExchange(erc20.launchboxExchange()).uniswapRouter()), router);
        assertEq(address(LaunchboxExchange(erc20.launchboxExchange()).token()), address(erc20));
        assertEq(LaunchboxExchange(erc20.launchboxExchange()).maxSupply(), maxSupply);
        assertEq(LaunchboxExchange(erc20.launchboxExchange()).marketCapThreshold(), marketCapThreshold);
        assertEq(LaunchboxExchange(erc20.launchboxExchange()).launchboxErc20Balance(), maxSupply);
        assertEq(LaunchboxExchange(erc20.launchboxExchange()).ethBalance(), 0);
        assertEq(LaunchboxExchange(erc20.launchboxExchange()).saleActive(), true);
    }

    function test_revert_initializeWithEmptyMetadata() public {
        vm.expectRevert(LaunchboxERC20.MetadataEmpty.selector);
        erc20.initialize(name, symbol, maxSupply, marketCapThreshold, "", exchangeImplementation, router);
    }

    function test_revert_initializeWithZeroMaxSupply() public {
        vm.expectRevert(LaunchboxERC20.CannotSellZeroTokens.selector);
        erc20.initialize(name, symbol, 0, marketCapThreshold, metadataUri, exchangeImplementation, router);
    }
}