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
    address public platformFeeReceiver = makeAddr("platformFeeReceiver");

    function test_initialize() public {
        assertEq(erc20.launchboxExchange(), address(0));
        LaunchboxERC20.InitializeParams memory params = LaunchboxERC20.InitializeParams(
            name,
            symbol,
            metadataUri,
            maxSupply,
            1,
            9,
            marketCapThreshold,
            exchangeImplementation,
            platformFeeReceiver,
            router,
            address(this)
        );
        erc20.initialize(
            params
        );
        assertNotEq(erc20.launchboxExchange(), address(0));
        assertEq(erc20.name(), name);
        assertEq(erc20.symbol(), symbol);
        assertEq(erc20.metadataURI(), metadataUri);
        assertEq(address(LaunchboxExchange(erc20.launchboxExchange()).aerodromeRouter()), router);
        assertEq(address(LaunchboxExchange(erc20.launchboxExchange()).token()), address(erc20));
        assertEq(LaunchboxExchange(erc20.launchboxExchange()).maxSupply(), maxSupply);
        assertEq(LaunchboxExchange(erc20.launchboxExchange()).marketCapThreshold(), marketCapThreshold);
        assertEq(LaunchboxExchange(erc20.launchboxExchange()).launchboxErc20Balance(), maxSupply);
        assertEq(LaunchboxExchange(erc20.launchboxExchange()).ethBalance(), 0);
        assertEq(LaunchboxExchange(erc20.launchboxExchange()).saleActive(), true);
    }

    function test_revert_initializeWithEmptyMetadata() public {
        vm.expectRevert(LaunchboxERC20.MetadataEmpty.selector);
        LaunchboxERC20.InitializeParams memory params = LaunchboxERC20.InitializeParams(
            name,
            symbol,
            "",
            maxSupply,
            0,
            0,
            marketCapThreshold,
            exchangeImplementation,
            address(0),
            router,
            address(this)
        );
        erc20.initialize(
            params
        );
    }

    function test_revert_initializeWithZeroMaxSupply() public {
        vm.expectRevert(LaunchboxERC20.CannotSellZeroTokens.selector);

        LaunchboxERC20.InitializeParams memory params = LaunchboxERC20.InitializeParams(
            name,
            symbol,
            metadataUri,
            0,
            0,
            0,
            marketCapThreshold,
            exchangeImplementation,
            address(0),
            router,
            address(this)
        );
        erc20.initialize(
            params
        );
    }

    function test_revert_initializeWithNonZeroPlatformFeeAndZeroReceiver() public {
        vm.expectRevert(LaunchboxERC20.PlatformFeeReceiverEmpty.selector);
        LaunchboxERC20.InitializeParams memory params = LaunchboxERC20.InitializeParams(
            name,
            symbol,
            metadataUri,
            100,
            1,
            9,
            marketCapThreshold,
            exchangeImplementation,
            address(0),
            router,
            address(this)
        );
        erc20.initialize(
            params
        );
    }
}
