// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IRouter} from "@aerodrome/contracts/contracts/interfaces/IRouter.sol";
import {IPool} from "@aerodrome/contracts/contracts/interfaces/IPool.sol";
import {console} from "forge-std/console.sol";

contract LaunchboxExchange {
    event ExchangeInitialized(
        address token,
        uint256 tradeFee,
        address feeReceiver,
        uint256 maxSupply
    );
    event TokenBuy(uint256 ethIn, uint256 tokenOut, uint256 fee, address buyer);
    event TokenSell(
        uint256 tokenIn,
        uint256 ethOut,
        uint256 fee,
        address seller
    );

    IPool public constant WETH_USDC_PAIR =
        IPool(0xcDAC0d6c6C59727a65F871236188350531885C43);
    uint256 public constant V_ETH_BALANCE = 1.5 ether;
    IERC20 public token;
    uint256 public maxSupply;
    uint256 public marketCapThreshold;
    uint256 public launchboxErc20Balance;
    uint256 public ethBalance;
    uint256 public tradeFee;
    address public feeReceiver;

    bool public saleActive;

    IRouter public aerodromeRouter;

    event BondingEnded(uint256 totalEth, uint256 totalTokens);

    error ExchangeInactive();
    error PurchaseExceedsSupply();
    error NotEnoughETH();
    error FeeTransferFailed();
    error MaxSupplyCannotBeLowerThanSuppliedTokens();

    function initialize(
        address _tokenAddress,
        address _feeReceiver,
        uint256 _tradeFee,
        uint256 _maxSupply,
        uint256 _marketCapThreshold,
        address _aerodromeRouter
    ) external payable {
        // sale is activate once the exchange is initialized
        saleActive = true;

        // register token
        token = IERC20(_tokenAddress);

        aerodromeRouter = IRouter(_aerodromeRouter);
        tradeFee = _tradeFee;
        maxSupply = _maxSupply;
        marketCapThreshold = _marketCapThreshold;

        // fee receiver
        feeReceiver = _feeReceiver;
        launchboxErc20Balance = token.balanceOf(address(this));

        if (msg.value != 0) {
            _buy(msg.value, msg.sender);
        }

        // register initial balance
        // assume whatever is in the exchange was meant to be sent to contract
        ethBalance = address(this).balance;

        if (maxSupply < launchboxErc20Balance) {
            revert MaxSupplyCannotBeLowerThanSuppliedTokens();
        }

        emit ExchangeInitialized(
            _tokenAddress,
            _tradeFee,
            _feeReceiver,
            _maxSupply
        );
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
        return _getSpotPrice();
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

    function getAmountOutWithFee(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 _tradeFee
    ) internal pure returns (uint256 amountOut, uint256 fee) {
        require(amountIn > 0, "Amount in must be greater than 0");
        require(
            reserveIn > 0 && reserveOut > 0,
            "Reserves must be greater than 0"
        );

        // Calculate fee
        uint256 feeNumerator = mul(amountIn, _tradeFee);
        fee = div(feeNumerator, 1000);

        // Calculate amountInWithFee
        uint256 amountInWithFee = sub(amountIn, fee);

        // Calculate numerator
        uint256 numerator = mul(amountInWithFee, reserveOut);

        // Calculate denominator
        uint256 reserveIn1000 = mul(reserveIn, 1000);
        uint256 amountInWithFee1000 = mul(amountInWithFee, 1000);
        uint256 denominator = add(
            reserveIn1000,
            div(amountInWithFee1000, amountIn)
        );

        require(denominator > 0, "Denominator must be greater than 0");

        // Calculate amountOut
        uint256 amountOut1000 = mul(numerator, 1000);
        amountOut = div(amountOut1000, denominator);

        return (amountOut, fee);
    }

    // SafeMath functions
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function calculatePurchaseTokenOut(
        uint256 amountETHIn
    ) public view returns (uint256, uint256) {
        uint256 tokenSupply = launchboxErc20Balance;
        return
            getAmountOutWithFee(
                amountETHIn,
                ethBalance + V_ETH_BALANCE,
                tokenSupply,
                tradeFee
            );
    }

    function calculateSaleTokenOut(
        uint256 amountTokenIn
    ) public view returns (uint256, uint256) {
        uint256 tokenSupply = launchboxErc20Balance;
        return
            getAmountOutWithFee(
                amountTokenIn,
                tokenSupply,
                ethBalance + V_ETH_BALANCE,
                tradeFee
            );
    }

    function _buy(uint256 ethAmount, address receiver) internal {
        // calculate tokens to mint and fee in eth
        (uint256 tokensToMint, uint256 feeInEth) = calculatePurchaseTokenOut(
            ethAmount
        );
        if (tokensToMint > launchboxErc20Balance) {
            revert PurchaseExceedsSupply();
        }
        if (feeInEth > 0) {
            (bool success, ) = feeReceiver.call{value: feeInEth}("");
            if (!success) {
                revert FeeTransferFailed();
            }
        }
        launchboxErc20Balance -= tokensToMint;
        ethBalance += (ethAmount - feeInEth);
        token.transfer(receiver, tokensToMint);

        emit TokenBuy(ethAmount, tokensToMint, feeInEth, receiver);
        if (_calculateMarketCap() >= marketCapThreshold) {
            endBonding();
        }
    }

    function _sell(uint256 tokenAmount, address receiver) internal {
        // calculate eth to refund and fee in token
        (uint256 ethToReturn, uint256 feeInToken) = calculateSaleTokenOut(
            tokenAmount
        );
        ethBalance -= ethToReturn;
        launchboxErc20Balance += (tokenAmount - feeInToken);
        require(
            token.transferFrom(receiver, address(this), tokenAmount),
            "Transfer failed"
        );
        if (feeInToken > 0) {
            token.transfer(feeReceiver, feeInToken);
        }
        if (address(this).balance < ethToReturn) {
            revert NotEnoughETH();
        }

        payable(receiver).transfer(ethToReturn);
        emit TokenSell(tokenAmount, ethToReturn, feeInToken, receiver);
    }

    function _calculateMarketCap() internal view returns (uint256) {
        return
            (maxSupply * (((_getSpotPrice()) * _getWETHPrice()) / 10 ** 18)) /
            10 ** 18;
    }

    receive() external payable {
        buyTokens();
    }

    function _getSpotPrice() internal view returns (uint256) {
        return ((ethBalance + 1.5 ether) * 10 ** 18) / launchboxErc20Balance;
    }

    function _getWETHPrice() internal view returns (uint256) {
        (uint256 _WETH_RESERVE, uint256 _USDC_RESERVE, ) = WETH_USDC_PAIR
            .getReserves();
        uint256 price = (_USDC_RESERVE * 10 ** 12 * 10 ** 18) / _WETH_RESERVE;
        return price;
    }
}
