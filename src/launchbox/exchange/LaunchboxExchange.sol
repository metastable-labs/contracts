// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IRouter} from "@aerodrome/contracts/contracts/interfaces/IRouter.sol";
import {IPool} from "@aerodrome/contracts/contracts/interfaces/IPool.sol";
import {AggregatorV3Interface} from "../token/interface/IV3Aggregator.sol";

contract LaunchboxExchange {
    event ExchangeInitialized(address token, uint256 tradeFee, address feeReceiver, uint256 maxSupply);
    event TokenBuy(uint256 ethIn, uint256 tokenOut, uint256 fee, address buyer);
    event TokenSell(uint256 tokenIn, uint256 ethOut, uint256 fee, address seller);

    IPool public constant WETH_USDC_PAIR = IPool(0xcDAC0d6c6C59727a65F871236188350531885C43);
    AggregatorV3Interface public constant CHAINLINK = AggregatorV3Interface(0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70);
    uint256 public constant CHAINLINK_DECIMALS = 8;
    uint256 public constant V_ETH_BALANCE = 1.5 ether;
    // Assume tradeFee is now represented in basis points (1/10000)
    // 10000 = 100%, 5000 = 50%, 100 = 1%, 1 = 0.01%
    uint256 public constant FEE_DENOMINATOR = 10_000;
    uint256 public constant LIQ_SLIPPAGE = 10; // 0.1%
    uint256 public constant MAX_DELAY = 45 * 60;

    IERC20 public token;
    uint256 public maxSupply;
    uint256 public marketCapThreshold;
    uint256 public launchboxErc20Balance;
    uint256 public ethBalance;
    uint256 public tradeFee;
    address public feeReceiver;
    address public calculatedPoolAddress;

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
        address _aerodromeRouter,
        address _initialBuyer
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
            // we don't need a check on initial buyer because, initial buyer will always be non-zero,
            // as initialBuyer is supplied by LaunchboxFactory as msg.sender
            _buy(msg.value, _initialBuyer);
        }

        // register initial balance
        // assume whatever is in the exchange was meant to be sent to contract
        ethBalance = address(this).balance;

        if (maxSupply < launchboxErc20Balance) {
            revert MaxSupplyCannotBeLowerThanSuppliedTokens();
        }

        // calculate and store pool addres
        // passing in factory address as zero so that router can select default factory
        calculatedPoolAddress =
            aerodromeRouter.poolFor(address(token), address(aerodromeRouter.weth()), false, address(0));

        emit ExchangeInitialized(_tokenAddress, _tradeFee, _feeReceiver, _maxSupply);
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

        // calculate minimum amount with 0.1% slippage
        uint256 amountTokenMin = mulDiv(totalTokens, FEE_DENOMINATOR - LIQ_SLIPPAGE, FEE_DENOMINATOR);
        uint256 amountEthMin = mulDiv(totalEth, FEE_DENOMINATOR - LIQ_SLIPPAGE, FEE_DENOMINATOR);

        // Add liquidity to Aerodrome
        aerodromeRouter.addLiquidityETH{value: totalEth}(
            address(token),
            false, // not stable pool
            totalTokens,
            amountTokenMin, // 0.1% slippage
            amountEthMin, // 0.1% slippage
            address(0xdead),
            block.timestamp
        );

        emit BondingEnded(totalEth, totalTokens);
    }

    function getAmountOutWithFee(uint256 amountIn, uint256 reserveIn, uint256 reserveOut, uint256 _tradeFee)
        internal
        pure
        returns (uint256 amountOut, uint256 fee)
    {
        require(amountIn > 0, "Amount in must be greater than 0");
        require(_tradeFee <= FEE_DENOMINATOR, "Trade fee must be less than or equal to 100%");
        require(reserveIn > 0 && reserveOut > 0, "Reserves must be greater than 0");

        uint256 amountInWithFee = mulDiv(amountIn, (FEE_DENOMINATOR - _tradeFee), 1);
        uint256 numerator = mulDiv(amountInWithFee, reserveOut, 1);
        uint256 denominator = reserveIn * FEE_DENOMINATOR + amountInWithFee;

        require(denominator > 0, "Denominator must be greater than 0");

        amountOut = mulDiv(numerator, 1, denominator);
        fee = ((amountIn * FEE_DENOMINATOR) - amountInWithFee) / FEE_DENOMINATOR;

        return (amountOut, fee);
    }

    // Helper function for safe multiplication and division
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        require(denominator > prod1);

        uint256 remainder;
        assembly {
            remainder := mulmod(x, y, denominator)
        }
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        uint256 twos = denominator & (~denominator + 1);
        assembly {
            denominator := div(denominator, twos)
        }

        assembly {
            prod0 := div(prod0, twos)
        }
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        uint256 inv = (3 * denominator) ^ 2;
        inv *= 2 - denominator * inv;
        inv *= 2 - denominator * inv;
        inv *= 2 - denominator * inv;
        inv *= 2 - denominator * inv;
        inv *= 2 - denominator * inv;
        inv *= 2 - denominator * inv;

        result = prod0 * inv;
        return result;
    }

    function calculatePurchaseTokenOut(uint256 amountETHIn) public view returns (uint256, uint256) {
        uint256 tokenSupply = launchboxErc20Balance;
        return getAmountOutWithFee(amountETHIn, ethBalance + V_ETH_BALANCE, tokenSupply, tradeFee);
    }

    function calculateSaleTokenOut(uint256 amountTokenIn) public view returns (uint256, uint256) {
        uint256 tokenSupply = launchboxErc20Balance;
        return getAmountOutWithFee(amountTokenIn, tokenSupply, ethBalance + V_ETH_BALANCE, tradeFee);
    }

    function _buy(uint256 ethAmount, address receiver) internal {
        // calculate tokens to mint and fee in eth
        (uint256 tokensToMint, uint256 feeInEth) = calculatePurchaseTokenOut(ethAmount);
        if (tokensToMint > launchboxErc20Balance) {
            revert PurchaseExceedsSupply();
        }
        if (feeInEth > 0) {
            (bool success,) = feeReceiver.call{value: feeInEth}("");
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
        (uint256 ethToReturn, uint256 feeInToken) = calculateSaleTokenOut(tokenAmount);
        ethBalance -= ethToReturn;
        launchboxErc20Balance += (tokenAmount - feeInToken);
        require(token.transferFrom(receiver, address(this), tokenAmount), "Transfer failed");
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
        uint256 spotPrice = _getSpotPrice();
        uint256 wethPrice = uint256(_getETHPrice());
        if (spotPrice > 10 ** 45) {
            return maxSupply * (((spotPrice / 10 ** 18) * wethPrice) / 10 ** 18);
        }
        return (maxSupply * ((spotPrice * wethPrice) / 10 ** 18)) / 10 ** 18;
    }

    receive() external payable {
        if (saleActive) {
            buyTokens();
        }
    }

    function _getSpotPrice() internal view returns (uint256) {
        return ((ethBalance + V_ETH_BALANCE) * 10 ** 18) / launchboxErc20Balance;
    }

    function _getWETHPrice() internal view returns (uint256) {
        (uint256 _WETH_RESERVE, uint256 _USDC_RESERVE,) = WETH_USDC_PAIR.getReserves();
        uint256 price = (_USDC_RESERVE * 10 ** 12 * 10 ** 18) / _WETH_RESERVE;
        return price;
    }

    function _getETHPrice() internal view returns (int256) {
        (uint80 roundID, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            CHAINLINK.latestRoundData();
        require(updatedAt >= block.timestamp - MAX_DELAY, "Stale price");
        return answer;
    }
}
