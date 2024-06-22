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

    function test_marketCap() public {
        assertLe(exchange.marketCap(), 6000 ether);
    }

    function test_tokenPriceinETH() public {
        assertEq(exchange.getTokenPriceinETH(), (1.5 ether) * 10 ** 18 / totalToBeSold);
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
        uint256 beforeBalance = 0;
        uint256 tokensReceived = 0;
        uint256 price = 0;
        exchange.buyTokens{value: 1 ether}();
        console.log("market cap");
        console.log(exchange.marketCap());
        tokensReceived = erc20.balanceOf(address(this)) - beforeBalance;
        price = 1 ether / (tokensReceived / (1 ether * 3500));
        console.log(tokensReceived);
        console.log(price);
        beforeBalance = erc20.balanceOf(address(this));
        exchange.buyTokens{value: 1 ether}();
        console.log("market cap");
        console.log(exchange.marketCap());
        tokensReceived = erc20.balanceOf(address(this)) - beforeBalance;
        price = 1 ether / (tokensReceived / (1 ether * 3500));
        console.log(tokensReceived);
        console.log(price);
        beforeBalance = erc20.balanceOf(address(this));
        exchange.buyTokens{value: 1 ether}();
        console.log("market cap");
        console.log(exchange.marketCap());
        tokensReceived = erc20.balanceOf(address(this)) - beforeBalance;
        price = 1 ether / (tokensReceived / (1 ether * 3500));
        console.log(tokensReceived);
        console.log(price);
        beforeBalance = erc20.balanceOf(address(this));
        exchange.buyTokens{value: 1 ether}();
        console.log("market cap");
        console.log(exchange.marketCap());
        tokensReceived = erc20.balanceOf(address(this)) - beforeBalance;
        price = 1 ether / (tokensReceived / (1 ether * 3500));
        console.log(tokensReceived);
        console.log(price);
        beforeBalance = erc20.balanceOf(address(this));
        exchange.buyTokens{value: 1 ether}();
        console.log("market cap");
        console.log(exchange.marketCap());
        tokensReceived = erc20.balanceOf(address(this)) - beforeBalance;
        price = 1 ether / (tokensReceived / (1 ether * 3500));
        console.log(tokensReceived);
        console.log(price);
        beforeBalance = erc20.balanceOf(address(this));

        // sell
        erc20.approve(address(exchange), beforeBalance);
        vm.expectRevert(LaunchboxExchange.ExchangeInactive.selector);
        exchange.sellTokens(beforeBalance);

        // cannot buy after pool is created
        vm.expectRevert(LaunchboxExchange.ExchangeInactive.selector);
        exchange.buyTokens{value: 1 ether}();
    }

    receive() external payable {}
}
