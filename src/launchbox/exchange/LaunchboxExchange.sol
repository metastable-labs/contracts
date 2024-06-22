// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IRouter} from "@aerodrome/contracts/contracts/interfaces/IRouter.sol";

contract LaunchboxExchange {
    uint256 public constant V_ETH_BALANCE = 1.5 ether;
    IERC20 public token;
    uint256 public maxSupply;
    uint256 public marketCapThreshold;
    uint256 public launchboxErc20Balance;
    uint256 public ethBalance;
    uint256 public tradeFee;
    address public feeReceiver;

    bool public saleActive = false;

    IRouter public aerodromeRouter;

    event BondingEnded(uint256 totalEth, uint256 totalTokens);

    error ExchangeInactive();
    error PurchaseExceedsSupply();
    error NotEnoughETH();
    error FeeTransferFailed();

    function initialize(
        address _tokenAddress,
        uint256 _tradeFee,
        uint256 _maxSupply,
        uint256 _marketCapThreshold,
        address _aerodromeRouter
    ) external payable {
        aerodromeRouter = IRouter(_aerodromeRouter);
        tradeFee = _tradeFee;
        maxSupply = _maxSupply;
        marketCapThreshold = _marketCapThreshold;
        // sale is activate once the exchange is initialized
        saleActive = true;

        // register token
        token = IERC20(_tokenAddress);

        // register initial balance
        // assume whatever is in the exchange was meant to be sent to contract
        ethBalance = address(this).balance;
        launchboxErc20Balance = token.balanceOf(address(this));

        if (msg.value != 0) {
            _buy(msg.value, msg.sender);
        }
    }

    function buyTokens() public payable {
        if (!saleActive) {
            revert ExchangeInactive();
        }
        _buy(msg.value, msg.sender);
    }

    function sellTokens(uint256 tokenAmount) public {
        if (!saleActive) {
            revert ExchangeInactive();
        }
        _sell(tokenAmount, msg.sender);
    }

    function marketCap() external view returns (uint256) {
        return _calculateMarketCap();
    }

    function getTokenPriceinETH() external view returns (uint256 ethAmount) {
        (uint256 amountOut, ) = calculateSaleTokenOut(1 * 1e18);
        return amountOut;
    }

    function endBonding() internal {
        // deactivate sale
        saleActive = false;

        // calculate total liquidity
        uint256 totalTokens = launchboxErc20Balance;
        uint256 totalEth = ethBalance;

        // Approve router to spend tokens
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

    function getAmountOutWithFee(uint256 amountIn, uint256 reserveIn, uint256 reserveOut, uint256 _tradeFee) internal pure returns (uint256, uint256) {
        require(amountIn > 0, "Amount in must be greater than 0");
        uint256 amountInWithFee = amountIn * (1000 - _tradeFee);
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        return (numerator / denominator, (amountIn * _tradeFee) / 1000);
    }

    function calculatePurchaseTokenOut(uint256 amountETHIn) public view returns (uint256, uint256 ) {
        uint256 tokenSupply = launchboxErc20Balance;
        return getAmountOutWithFee(amountETHIn, ethBalance + V_ETH_BALANCE, tokenSupply, tradeFee);
    }

    function calculateSaleTokenOut(uint256 amountTokenIn) public view returns (uint256, uint256 ) {
        uint256 tokenSupply = launchboxErc20Balance;
        return getAmountOutWithFee(amountTokenIn, tokenSupply, ethBalance + V_ETH_BALANCE, tradeFee);
    }

    function _buy(uint256 ethAmount, address _receiver) internal {
        // calculate tokens to mint and fee in eth
        (uint256 tokensToMint, uint256 feeInEth) = calculatePurchaseTokenOut(ethAmount);
        if (tokensToMint > launchboxErc20Balance) {
            revert PurchaseExceedsSupply();
        }
        if(feeInEth > 0) {
            (bool success, ) = feeReceiver.call{value: feeInEth}("");
            if(!success) {
                revert FeeTransferFailed();
            }
        }

        launchboxErc20Balance -= tokensToMint;
        ethBalance += (ethAmount - feeInEth);
        token.transfer(_receiver, tokensToMint);

        if (_calculateMarketCap() >= marketCapThreshold) {
            endBonding();
        }
    }

    function _sell(uint256 tokenAmount,address receiver) internal {
        // calculate eth to refund and fee in token
        (uint256 ethToReturn, uint256 feeInToken) = calculateSaleTokenOut(tokenAmount);
        ethBalance -= ethToReturn;
        launchboxErc20Balance += (tokenAmount - feeInToken);
        require(token.transferFrom(receiver, address(this), tokenAmount), "Transfer failed");
        if(feeInToken > 0) {
            token.transfer(feeReceiver, feeInToken);
        }
        if (address(this).balance < ethToReturn) {
            revert NotEnoughETH();
        }

        payable(receiver).transfer(ethToReturn);
    }

    function _calculateMarketCap() internal view returns (uint256) {
        return ethBalance;
    }

    receive() external payable {
        buyTokens();
    }
}
