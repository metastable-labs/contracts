pragma solidity ^0.8.20;

import {LaunchboxExchangeBase, LaunchboxExchange} from "../base/LaunchboxExchange.base.sol";
import {console} from "forge-std/console.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {console} from "forge-std/console.sol";

// do fork testing
// forge test --mc LaunchboxExchangeUnit_Fork --fork-url https://base-rpc.publicnode.com
contract LaunchboxExchangeUnit_Fork is LaunchboxExchangeBase {
    function getAmountOutWithFee(uint256 amountIn, uint256 reserveIn, uint256 reserveOut, uint256 _tradeFee)
        internal
        pure
        returns (uint256, uint256)
    {
        require(amountIn > 0, "Amount in must be greater than 0");
        uint256 amountInWithFee = amountIn * (1000 - _tradeFee);
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        return (numerator / denominator, (amountIn * _tradeFee) / 1000);
    }

    function test_revert_initializeMaxSupplyLowerThanSuppliedTokens() public {
        LaunchboxExchange exchangeImpl = new LaunchboxExchange();
        exchange = LaunchboxExchange(payable(Clones.clone(address(exchangeImpl))));
        erc20.mint(address(exchange), totalToBeSold);
        erc20.mint(protocol, platformFee);
        erc20.mint(community, communityShare);
        vm.expectRevert(LaunchboxExchange.MaxSupplyCannotBeLowerThanSuppliedTokens.selector);
        exchange.initialize(address(erc20), feeReceiver, tradeFee, platformFee, marketCapThreshold, router);
    }

    function test_initialize() public {
        LaunchboxExchange exchangeImpl = new LaunchboxExchange();
        exchange = LaunchboxExchange(payable(Clones.clone(address(exchangeImpl))));
        erc20.mint(address(exchange), totalToBeSold);
        erc20.mint(protocol, platformFee);
        erc20.mint(community, communityShare);
        exchange.initialize(address(erc20), feeReceiver, tradeFee, maxSupply, marketCapThreshold, router);
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
        exchange.initialize{value: 1e17}(address(erc20), feeReceiver, tradeFee, maxSupply, marketCapThreshold, router);
        assertEq(address(exchange.token()), address(erc20));
        assertEq(exchange.maxSupply(), maxSupply);
        assertEq(exchange.marketCapThreshold(), marketCapThreshold);
        assertEq(exchange.launchboxErc20Balance(), totalToBeSold - tokenAmountOut);
        assertEq(exchange.ethBalance(), 1e17 - fee);
        assertEq(erc20.balanceOf(address(this)), tokenAmountOut);
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
        (uint256 tokenAmountOut, uint256 fee) = getAmountOutWithFee(1e10,1.5 ether, totalToBeSold, tradeFee);
        exchange.initialize{value: 1e10}(address(erc20), feeReceiver, tradeFee, maxSupply, marketCapThreshold, router);
        assertEq(address(exchange.token()), address(erc20));
        assertEq(exchange.maxSupply(), maxSupply);
        assertEq(exchange.marketCapThreshold(), marketCapThreshold);
        assertEq(exchange.launchboxErc20Balance(), totalToBeSold - tokenAmountOut);
        assertEq(exchange.ethBalance(), 1e10 - fee);
        assertEq(erc20.balanceOf(address(this)), tokenAmountOut);
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
        // the whole world GDP is at 29 Billion ETH, which is 1.9 * 10 ^ 10.
        _ethAmount = bound(_ethAmount, 1, 10**45);
        vm.deal(address(this), _ethAmount);
        exchange.buyTokens{value: _ethAmount}();
    }

    function test_buy_MaxValue() public {
        vm.deal(address(this), 10**45);
        exchange.buyTokens{value: 10**45}();
    }

    function test_sell_maxValue() public {
        vm.deal(address(this), 10**45);
        exchange.buyTokens{value: 10**45}();
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

    function test_sell_fuzz(uint256 _ethAmount,uint256 _tokenSellAmount) public {
        _ethAmount = bound(_ethAmount, 1, 10**45);
        _tokenSellAmount = bound(_tokenSellAmount, 1, 10**45);
        vm.deal(address(this), _ethAmount);
        exchange.buyTokens{value: _ethAmount}();

        // sell
        erc20.approve(address(exchange), _tokenSellAmount);
        if(exchange.marketCap() > marketCapThreshold) {
            vm.expectRevert(LaunchboxExchange.ExchangeInactive.selector);
            exchange.sellTokens(_tokenSellAmount);
        } else {
            if(_tokenSellAmount > erc20.balanceOf(address(this))) {
                vm.expectRevert();
            }
            exchange.sellTokens(_tokenSellAmount);
        }
    }

    receive() external payable {}
}
