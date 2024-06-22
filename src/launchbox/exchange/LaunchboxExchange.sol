// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IRouter} from "@aerodrome/contracts/contracts/interfaces/IRouter.sol";

contract LaunchboxExchange {
    IERC20 public token;
    uint256 public maxSupply;
    uint256 public marketCapThreshold;
    uint256 public launchboxErc20BalanceReceived;
    uint256 public launchboxErc20Balance;
    uint256 public ethBalance;
    uint32 public reserveRatio;

    bool public saleActive = false;

    IRouter public aerodromeRouter;

    event BondingEnded(uint256 totalEth, uint256 totalTokens);

    error ExchangeInactive();
    error PurchaseExceedsSupply();
    error NotEnoughETH();

    function initialize(
        address _tokenAddress,
        uint256 _maxSupply,
        uint256 _marketCapThreshold,
        address _aerodromeRouter
    ) external payable {
        aerodromeRouter = IRouter(_aerodromeRouter);
        token = IERC20(_tokenAddress);
        maxSupply = _maxSupply;
        marketCapThreshold = _marketCapThreshold;
        launchboxErc20Balance = token.balanceOf(address(this));
        launchboxErc20BalanceReceived = launchboxErc20Balance;
        reserveRatio = 100_000; // 10%
        ethBalance = address(this).balance;
        saleActive = true;
    }

    function buyTokens() public payable {
        if (!saleActive) {
            revert ExchangeInactive();
        }
        // Example bonding curve pricing logic
        uint256 tokensToMint = _convertToPurchaseTokens(msg.value);
        if (tokensToMint > launchboxErc20Balance) {
            revert PurchaseExceedsSupply();
        }

        launchboxErc20Balance -= tokensToMint;
        ethBalance += msg.value;
        token.transfer(msg.sender, tokensToMint);

        if (_calculateMarketCap() >= marketCapThreshold) {
            endBonding();
        }
    }

    function _calculateMarketCap() internal view returns (uint256) {
        return ethBalance;
    }

    function _convertToPurchaseTokens(uint256 ethAmount) internal view returns (uint256 tokenAmount) {
        return calculatePurchaseTokenOut(ethAmount);
    }

    function _convertToSellTokens(uint256 tokenAmount) internal view returns (uint256 ethAmount) {
        return calculateSaleTokenOut(tokenAmount);
    }

    function calculateMarketCap() external view returns (uint256) {
        return _calculateMarketCap();
    }

    function getTokenPriceinETH() external view returns (uint256 ethAmount) {
        return _convertToSellTokens(1 * 1e18);
    }

    function sellTokens(uint256 tokenAmount) public {
        if (!saleActive) {
            revert ExchangeInactive();
        }

        uint256 ethToReturn = _convertToSellTokens(tokenAmount); // simplistic example
        ethBalance -= ethToReturn;
        launchboxErc20Balance += tokenAmount;
        require(token.transferFrom(msg.sender, address(this), tokenAmount), "Transfer failed");
        if (address(this).balance < ethToReturn) {
            revert NotEnoughETH();
        }

        payable(msg.sender).transfer(ethToReturn);
    }

    function endBonding() internal {
        saleActive = false;
        uint256 totalTokens = token.balanceOf(address(this));
        uint256 totalEth = address(this).balance;

        // Approve Uniswap router to spend tokens
        token.approve(address(aerodromeRouter), totalTokens);

        // Add liquidity to Uniswap
        aerodromeRouter.addLiquidityETH{value: totalEth}(
            address(token),
            false, // not stable pool
            totalTokens,
            0, // slippage is okay
            0, // slippage is okay
            address(0xdead),
            block.timestamp
        );

        emit BondingEnded(totalEth, totalTokens);
    }

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256) {
        require(amountIn > 0, "Amount in must be greater than 0");
        uint256 amountInWithFee = amountIn * 1000; // assuming 0.3% fee
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        return numerator / denominator;
    }

    function calculatePurchaseTokenOut(uint256 amountETHIn) public view returns (uint256) {
        uint256 tokenSupply = launchboxErc20Balance;
        return getAmountOut(amountETHIn, ethBalance + 1.5 ether, tokenSupply);
    }

    function calculateSaleTokenOut(uint256 amountTokenIn) public view returns (uint256) {
        uint256 tokenSupply = launchboxErc20Balance;
        return getAmountOut(amountTokenIn, tokenSupply, ethBalance + 1.5 ether);
    }

    receive() external payable {
        buyTokens();
    }
}
