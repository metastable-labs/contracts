pragma solidity ^0.8.20;

import {LaunchboxExchangeBase} from "../base/LaunchboxExchange.base.sol";
import {console} from "forge-std/console.sol";

contract LaunchboxExchangeUnit is LaunchboxExchangeBase {
    function test_buy() public {
        uint256 beforeBalance = 0;
        uint256 tokensReceived = 0;
        uint256 price = 0;
        exchange.buyTokens{value: 1 ether}();
        tokensReceived = erc20.balanceOf(address(this)) - beforeBalance;
        price = 1 ether / (tokensReceived / (1 ether * 3500));
        console.log(tokensReceived);
        console.log(price);
        beforeBalance = erc20.balanceOf(address(this));
        exchange.buyTokens{value: 1 ether}();
        tokensReceived = erc20.balanceOf(address(this)) - beforeBalance;
        price = 1 ether / (tokensReceived / (1 ether * 3500));
        console.log(tokensReceived);
        console.log(price);
        beforeBalance = erc20.balanceOf(address(this));
        exchange.buyTokens{value: 1 ether}();
        tokensReceived = erc20.balanceOf(address(this)) - beforeBalance;
        price = 1 ether / (tokensReceived / (1 ether * 3500));
        console.log(tokensReceived);
        console.log(price);
        beforeBalance = erc20.balanceOf(address(this));
        exchange.buyTokens{value: 1 ether}();
        tokensReceived = erc20.balanceOf(address(this)) - beforeBalance;
        price = 1 ether / (tokensReceived / (1 ether * 3500));
        console.log(tokensReceived);
        console.log(price);
        beforeBalance = erc20.balanceOf(address(this));
        exchange.buyTokens{value: 1 ether}();
        tokensReceived = erc20.balanceOf(address(this)) - beforeBalance;
        price = 1 ether / (tokensReceived / (1 ether * 3500));
        console.log(tokensReceived);
        console.log(price);
        beforeBalance = erc20.balanceOf(address(this));

        // sell
        uint256 beforeSellBalance = address(this).balance;
        erc20.approve(address(exchange), beforeBalance);
        exchange.sellTokens(beforeBalance);
        console.log(address(this).balance - beforeSellBalance);
        // console.log(beforeBalance - erc20.balanceOf(address(this)));
        // beforeBalance = erc20.balanceOf(address(this));
        // exchange.buyTokens{value: 1 ether}();
        // console.log(beforeBalance - erc20.balanceOf(address(this)));
        // beforeBalance = erc20.balanceOf(address(this));
        // exchange.buyTokens{value: 1 ether}();
        // console.log(beforeBalance - erc20.balanceOf(address(this)));
        // beforeBalance = erc20.balanceOf(address(this));
        // exchange.buyTokens{value: 1 ether}();
        // console.log(beforeBalance - erc20.balanceOf(address(this)));
        // beforeBalance = erc20.balanceOf(address(this));
        // exchange.buyTokens{value: 1 ether}();
        // console.log(beforeBalance - erc20.balanceOf(address(this)));
        // beforeBalance = erc20.balanceOf(address(this));
    }

    receive() external payable {}
}
