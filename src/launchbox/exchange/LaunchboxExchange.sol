// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract LaunchboxExchange {
    IERC20 public token;
    uint256 public maxSupply;
    uint256 public marketCapThreshold;
    uint256 public launchboxErc20Balance;
    uint256 public ethBalance;

    bool public saleActive = false;

    IUniswapV2Router02 public uniswapRouter;

    event BondingEnded(uint256 totalEth, uint256 totalTokens);

    error ExchangeInactive();
    error PurchaseExceedsSupply();
    error NotEnoughETH();

    function initialize(address _tokenAddress, uint256 _maxSupply, uint256 _marketCapThreshold, address _uniswapRouter) external {
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        token = IERC20(_tokenAddress);
        maxSupply = _maxSupply;
        marketCapThreshold = _marketCapThreshold;
        launchboxErc20Balance = token.balanceOf(address(this));
        ethBalance = address(this).balance;
        saleActive = true;
    }

    function buyTokens() public payable {
        if (!saleActive) {
            revert ExchangeInactive();
        }
        // Example bonding curve pricing logic
        uint256 tokensToMint = _convertToPurchaseTokens(msg.value);
        if(tokensToMint > launchboxErc20Balance) {
            revert PurchaseExceedsSupply();
        }

        launchboxErc20Balance -= tokensToMint;
        ethBalance += msg.value;
        token.transfer(msg.sender, tokensToMint);

        if (_calculateMarketCap() >= marketCapThreshold) {
            endBonding();
        }
    }

    function _calculateMarketCap() internal view returns(uint256) {
        return ethBalance;
    }

    function _convertToPurchaseTokens(uint256 ethAmount) internal view returns(uint256 tokenAmount) {
        return ethAmount;
    }

    function _convertToSellTokens(uint256 tokenAmount) internal view returns(uint256 ethAmount) {
        return tokenAmount;
    }

    function sellTokens(uint256 tokenAmount) public {
        if (!saleActive) {
            revert ExchangeInactive();
        }

        uint256 ethToReturn = _convertToSellTokens(tokenAmount); // simplistic example
        ethBalance -=  ethToReturn;
        launchboxErc20Balance += tokenAmount;
        require(token.transferFrom(msg.sender, address(this), tokenAmount), "Transfer failed");
        if(address(this).balance < ethToReturn) {
            revert NotEnoughETH();
        }

        payable(msg.sender).transfer(ethToReturn);
    }

    function endBonding() internal {
        saleActive = false;
        uint256 totalTokens = token.balanceOf(address(this));
        uint256 totalEth = address(this).balance;

        // Approve Uniswap router to spend tokens
        token.approve(address(uniswapRouter), totalTokens);

        // Add liquidity to Uniswap
        uniswapRouter.addLiquidityETH{value: totalEth}(
            address(token),
            totalTokens,
            0, // slippage is okay
            0, // slippage is okay
            address(0xdead),
            block.timestamp
        );

        emit BondingEnded(totalEth, totalTokens);
    }

    receive() external payable {
        buyTokens();
    }
}
