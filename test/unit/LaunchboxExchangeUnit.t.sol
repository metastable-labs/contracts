pragma solidity ^0.8.20;

import {LaunchboxExchangeBase, LaunchboxExchange} from "../base/LaunchboxExchange.base.sol";
import {console} from "forge-std/console.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

// do fork testing
// forge test --mc LaunchboxExchangeUnit_Fork --fork-url https://base-rpc.publicnode.com
contract LaunchboxExchangeUnit_Fork is LaunchboxExchangeBase {
    function getAmountOutWithFee(uint256 amountIn, uint256 reserveIn, uint256 reserveOut, uint256 _tradeFee)
        internal
        pure
        returns (uint256 amountOut, uint256 fee)
    {
        uint256 amountInWithFee = amountIn * (10000 - _tradeFee);
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 10000 + amountInWithFee;

        amountOut = numerator/denominator;
        fee = ((amountIn * 10000) - amountInWithFee)/10000;

        return (amountOut, fee);
    }

    function test_revert_initializeMaxSupplyLowerThanSuppliedTokens() public {
        LaunchboxExchange exchangeImpl = new LaunchboxExchange();
        exchange = LaunchboxExchange(payable(Clones.clone(address(exchangeImpl))));
        erc20.mint(address(exchange), totalToBeSold);
        erc20.mint(protocol, platformFee);
        erc20.mint(community, communityShare);
        vm.expectRevert(LaunchboxExchange.MaxSupplyCannotBeLowerThanSuppliedTokens.selector);
        exchange.initialize(address(erc20), feeReceiver, tradeFee, platformFee, marketCapThreshold, router, initialBuyer);
    }

    function test_initialize() public {
        LaunchboxExchange exchangeImpl = new LaunchboxExchange();
        exchange = LaunchboxExchange(payable(Clones.clone(address(exchangeImpl))));
        erc20.mint(address(exchange), totalToBeSold);
        erc20.mint(protocol, platformFee);
        erc20.mint(community, communityShare);
        exchange.initialize(address(erc20), feeReceiver, tradeFee, maxSupply, marketCapThreshold, router, initialBuyer);
        assertEq(address(exchange.token()), address(erc20));
        assertEq(exchange.maxSupply(), maxSupply);
        assertEq(exchange.marketCapThreshold(), marketCapThreshold);
        assertEq(exchange.launchboxErc20Balance(), totalToBeSold);
        assertEq(exchange.ethBalance(), 0);
        assertEq(exchange.tradeFee(), tradeFee);
        assertEq(exchange.feeReceiver(), feeReceiver);
        assertEq(exchange.saleActive(), true);
        assertEq(address(exchange.aerodromeRouter()), router);
    }

    function test_initializeWithInitialBuy() public {
        LaunchboxExchange exchangeImpl = new LaunchboxExchange();
        exchange = LaunchboxExchange(payable(Clones.clone(address(exchangeImpl))));
        erc20.mint(address(exchange), totalToBeSold);
        erc20.mint(protocol, platformFee);
        erc20.mint(community, communityShare);
        (uint256 tokenAmountOut, uint256 fee) = getAmountOutWithFee(1e17, 1.5 ether, totalToBeSold, tradeFee);
        exchange.initialize{value: 1e17}(address(erc20), feeReceiver, tradeFee, maxSupply, marketCapThreshold, router, initialBuyer);
        assertEq(address(exchange.token()), address(erc20));
        assertEq(exchange.maxSupply(), maxSupply);
        assertEq(exchange.marketCapThreshold(), marketCapThreshold);
        assertEq(exchange.launchboxErc20Balance(), totalToBeSold - tokenAmountOut);
        assertEq(exchange.ethBalance(), 1e17 - fee);
        assertEq(erc20.balanceOf(initialBuyer), tokenAmountOut);
        assertEq(feeReceiver.balance, fee);
        assertEq(exchange.tradeFee(), tradeFee);
        assertEq(exchange.feeReceiver(), feeReceiver);
        assertEq(exchange.saleActive(), true);
        assertEq(address(exchange.aerodromeRouter()), router);
    }

    function test_initializeWithInitialBuyWithLowEth() public {
        LaunchboxExchange exchangeImpl = new LaunchboxExchange();
        exchange = LaunchboxExchange(payable(Clones.clone(address(exchangeImpl))));
        erc20.mint(address(exchange), totalToBeSold);
        erc20.mint(protocol, platformFee);
        erc20.mint(community, communityShare);
        (uint256 tokenAmountOut, uint256 fee) = getAmountOutWithFee(1e10, 1.5 ether, totalToBeSold, tradeFee);
        exchange.initialize{value: 1e10}(address(erc20), feeReceiver, tradeFee, maxSupply, marketCapThreshold, router, initialBuyer);
        assertEq(address(exchange.token()), address(erc20));
        assertEq(exchange.maxSupply(), maxSupply);
        assertEq(exchange.marketCapThreshold(), marketCapThreshold);
        assertEq(exchange.launchboxErc20Balance(), totalToBeSold - tokenAmountOut);
        assertEq(exchange.ethBalance(), 1e10 - fee);
        assertEq(erc20.balanceOf(initialBuyer), tokenAmountOut);
        assertEq(feeReceiver.balance, fee);
        assertEq(exchange.tradeFee(), tradeFee);
        assertEq(exchange.feeReceiver(), feeReceiver);
        assertEq(exchange.saleActive(), true);
        assertEq(address(exchange.aerodromeRouter()), router);
    }

    function test_marketCap() public {
        assertLe(exchange.marketCap(), 6000 ether);
    }

    function test_tokenPriceinETH() public {
        assertEq(exchange.getTokenPriceinETH(), ((1.5 ether) * 10 ** 18) / totalToBeSold);
    }

    function test_buy() public {
        exchange.buyTokens{value: 1 ether}();
    }

    function test_sell() public {
        exchange.buyTokens{value: 1 ether}();
        erc20.approve(address(exchange), erc20.balanceOf(address(this)));
        exchange.sellTokens(erc20.balanceOf(address(this)));
    }

    function test_buyToCreatingLiquidityPool() public {
        uint256 currentMarketCap;
        uint256 beforeBalance = 0;
        while (currentMarketCap < marketCapThreshold) {
            exchange.buyTokens{value: 1 ether}();
            currentMarketCap = exchange.marketCap();
            console.log("market cap");
            console.log(currentMarketCap);
            beforeBalance = erc20.balanceOf(address(this));
        }

        // sell
        erc20.approve(address(exchange), beforeBalance);
        vm.expectRevert(LaunchboxExchange.ExchangeInactive.selector);
        exchange.sellTokens(beforeBalance);

        // cannot buy after pool is created
        vm.expectRevert(LaunchboxExchange.ExchangeInactive.selector);
        exchange.buyTokens{value: 1 ether}();
    }

    function test_buy_fuzz(uint256 _ethAmount) public {
        // no one in right mind will invest more than 10^45 ETH.
        // the whole world GDP is at 29 Billion ETH, which is 2.9 * 10 ^ 28.
        _ethAmount = bound(_ethAmount, 1, 10 ** 45);
        vm.deal(address(this), _ethAmount);
        exchange.buyTokens{value: _ethAmount}();
    }

    function test_buy_MaxValue() public {
        vm.deal(address(this), 10 ** 45);
        exchange.buyTokens{value: 10 ** 45}();
    }

    function test_sell_maxValue() public {
        vm.deal(address(this), 10 ** 45);
        exchange.buyTokens{value: 10 ** 45}();
        uint256 balance = erc20.balanceOf(address(this));
        vm.expectRevert(LaunchboxExchange.ExchangeInactive.selector);
        exchange.sellTokens(balance);
    }

    function test_buy_minValue() public {
        assertEq(erc20.balanceOf(address(this)), 0);
        exchange.buyTokens{value: 1}();
        assertNotEq(erc20.balanceOf(address(this)), 0);
    }

    function test_sell_minValue() public {
        exchange.buyTokens{value: 1}();

        assertNotEq(erc20.balanceOf(address(this)), 0);
        erc20.approve(address(exchange), type(uint256).max);
        exchange.sellTokens(erc20.balanceOf(address(this)));
        assertEq(erc20.balanceOf(address(this)), 0);
    }

    function test_sell_fuzz(uint256 _ethAmount, uint256 _tokenSellAmount) public {
        _ethAmount = bound(_ethAmount, 1, 10 ** 45);
        _tokenSellAmount = bound(_tokenSellAmount, 1, 10 ** 45);
        vm.deal(address(this), _ethAmount);
        exchange.buyTokens{value: _ethAmount}();

        // sell
        erc20.approve(address(exchange), _tokenSellAmount);
        if (exchange.marketCap() > marketCapThreshold) {
            vm.expectRevert(LaunchboxExchange.ExchangeInactive.selector);
            exchange.sellTokens(_tokenSellAmount);
        } else {
            if (_tokenSellAmount > erc20.balanceOf(address(this))) {
                vm.expectRevert();
            }
            exchange.sellTokens(_tokenSellAmount);
        }
    }

    function test_buy_sell(uint256 _ethAmount) public {
        // buyer 1
        address buyer1 = makeAddr("buyer1");
        address buyer2 = makeAddr("buyer2");
        vm.deal(address(this), 20 ether);
        vm.deal(buyer1, 20 ether);
        vm.deal(buyer2, 20 ether);
        _ethAmount = bound(_ethAmount, 1, 1 * 10 ** 18);
        uint256 buyer2BeforeBalance = buyer2.balance;
        // buy
        exchange.buyTokens{value: _ethAmount}();
        vm.prank(buyer1);
        exchange.buyTokens{value: _ethAmount}();
        vm.prank(buyer2);
        exchange.buyTokens{value: _ethAmount}();
        // tokens bought
        uint256 buyer2TokensBought = erc20.balanceOf(buyer2);
        // approve
        vm.prank(buyer2);
        erc20.approve(address(exchange), buyer2TokensBought);
        // sell
        vm.prank(buyer2);
        exchange.sellTokens(buyer2TokensBought);
        uint256 buyer2AfterSellBalance = buyer2.balance;
        assertLt(buyer2AfterSellBalance, buyer2BeforeBalance);
    }

    receive() external payable {}
}
