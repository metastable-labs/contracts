pragma solidity ^0.8.20;

import {LaunchboxERC20Base} from "../base/LaunchboxERC20.base.sol";
import {LaunchboxFactory} from "../../src/launchbox/token/LaunchboxFactory.sol";
import {LaunchboxERC20} from "../../src/launchbox/token/LaunchboxERC20.sol";
import {LaunchboxExchange} from "../../src/launchbox/exchange/LaunchboxExchange.sol";
import {IRouter} from "@aerodrome/contracts/contracts/interfaces/IRouter.sol";
import {IPoolFactory} from "@aerodrome/contracts/contracts/interfaces/factories/IPoolFactory.sol";
import {console} from "forge-std/console.sol";

// do fork testing
// forge test --mc _Fork --fork-url https://base-rpc.publicnode.com
contract LaunchboxERC20Unit_Fork is LaunchboxERC20Base {
    string public name = "ERC20";
    string public symbol = "ERC20_SYMBOL";
    uint256 public maxSupply = 1_000_000e18;
    uint256 public marketCapThreshold = 100_000e18;
    string public metadataUri = "ipfs://metadata";
    address public router = 0xcF77a3Ba9A5CA399B7c97c74d54e5b1Beb874E43;
    address public platformFeeReceiver = makeAddr("platformFeeReceiver");

    function test_initialize() public {
        assertEq(erc20.launchboxExchange(), address(0));
        LaunchboxERC20.InitializeParams memory params = LaunchboxERC20.InitializeParams(
            name,
            symbol,
            metadataUri,
            0,
            maxSupply,
            1,
            9,
            marketCapThreshold,
            exchangeImplementation,
            platformFeeReceiver,
            router,
            address(this)
        );
        erc20.initialize(params);
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
            0,
            maxSupply,
            0,
            0,
            marketCapThreshold,
            exchangeImplementation,
            address(0),
            router,
            address(this)
        );
        erc20.initialize(params);
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
            0,
            marketCapThreshold,
            exchangeImplementation,
            address(0),
            router,
            address(this)
        );
        erc20.initialize(params);
    }

    function test_revert_initializeWithNonZeroPlatformFeeAndZeroReceiver() public {
        vm.expectRevert(LaunchboxERC20.PlatformFeeReceiverEmpty.selector);
        LaunchboxERC20.InitializeParams memory params = LaunchboxERC20.InitializeParams(
            name,
            symbol,
            metadataUri,
            0,
            100,
            1,
            9,
            marketCapThreshold,
            exchangeImplementation,
            address(0),
            router,
            address(this)
        );
        erc20.initialize(params);
    }

    modifier initializeContracts() {
        LaunchboxERC20.InitializeParams memory params = LaunchboxERC20.InitializeParams(
            name,
            symbol,
            metadataUri,
            0,
            maxSupply,
            1,
            9,
            marketCapThreshold,
            exchangeImplementation,
            platformFeeReceiver,
            router,
            address(this)
        );
        erc20.initialize(params);
        _;
    }

    function test_revert_TransferToPoolBeforeSaleComplete() public initializeContracts {
        LaunchboxExchange exchange = LaunchboxExchange(erc20.launchboxExchange());
        address buyer = makeAddr("buyer");
        vm.deal(buyer, 5 ether);

        address attacker = makeAddr("attacker");
        vm.deal(attacker, 8 ether);
        // IPool newPool = IPool(IRouter(router).poolFor(address(token), WETH, false, aerodromeFactory));

        console.log("attacker ETH balance before: %e", attacker.balance);

        // Normal user buys tokens
        vm.prank(buyer);
        exchange.buyTokens{value: 1 ether}();

        // Attacker buys small amount of tokens
        vm.startPrank(attacker);
        exchange.buyTokens{value: 1e15 wei}();

        address calculatedPoolAddress = exchange.calculatedPoolAddress();
        uint256 erc20Balance = erc20.balanceOf(attacker);

        vm.expectRevert(LaunchboxERC20.CannotDepositLiquidityBeforeSaleEnds.selector);
        erc20.transfer(calculatedPoolAddress, erc20Balance);

        erc20.approve(calculatedPoolAddress, erc20Balance);

        vm.stopPrank();

        vm.prank(calculatedPoolAddress);
        vm.expectRevert(LaunchboxERC20.CannotDepositLiquidityBeforeSaleEnds.selector);
        erc20.transferFrom(attacker, calculatedPoolAddress, erc20Balance);
    }

    function test_revert_createLiquidityPoolBeforeSaleEnds() public initializeContracts {
        LaunchboxExchange exchange = LaunchboxExchange(erc20.launchboxExchange());
        address buyer = makeAddr("buyer");
        vm.deal(buyer, 5 ether);

        address attacker = makeAddr("attacker");
        vm.deal(attacker, 8 ether);
        // IPool newPool = IPool(IRouter(router).poolFor(address(token), WETH, false, aerodromeFactory));

        console.log("attacker ETH balance before: %e", attacker.balance);

        // Normal user buys tokens
        vm.prank(buyer);
        exchange.buyTokens{value: 1 ether}();

        // Attacker buys small amount of tokens
        vm.startPrank(attacker);
        exchange.buyTokens{value: 1e15 wei}();

        // Attacker adds 1000 Wei of ETH and 1 Wei of tokens (Crud exchange rate)
        erc20.approve(address(router), 1e50);
        vm.expectRevert(); // CannotDepositLiquidityBeforeSaleEnds but on internal trx and the whole trx reverts with EVM revert
        IRouter(router).addLiquidityETH{value: 1e18 wei}(address(erc20), false, 1 wei ,0 ,0, address(0xdead), block.timestamp);

        vm.stopPrank();

        vm.startPrank(attacker);

        // This deposits the ETH and tokens into the pool
        exchange.buyTokens{value: 6 ether}();

        IRouter.Route[] memory routes = new IRouter.Route[](1);
        routes[0] = IRouter.Route(address(erc20), address(IRouter(router).weth()), false, IRouter(router).defaultFactory());

        // Attacker swaps their tokens for ETH at a very cheap price, using liquidity provided by the LaunchboxExchange
        IRouter(router).swapExactTokensForETH(erc20.balanceOf(attacker), 0, routes, attacker, block.timestamp + 1000);
        vm.stopPrank();

        console.log("attacker ETH balance after: %e", attacker.balance);
    }
}
