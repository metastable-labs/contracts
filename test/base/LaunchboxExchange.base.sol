pragma solidity ^0.8.20;

import {LaunchboxExchange} from "../../src/launchbox/exchange/LaunchboxExchange.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Test} from "forge-std/Test.sol";

contract LaunchboxExchangeBase is Test {
    LaunchboxExchange public exchange;
    ERC20Mock public erc20;
    address public factory = makeAddr("factory");
    address public exchangeImplementation;
    uint256 public HUNDRED_PERCENTAGE = 100 * 1e18;
    uint256 public maxSupply = 1_000_000_000 ether;
    uint256 public marketCapThreshold = 100_000 ether;
    uint256 public platformFee = 1 * 1e18; // 1 %
    uint256 public platformShare = maxSupply * platformFee / HUNDRED_PERCENTAGE;
    uint256 public communityFee = 1 * 1e18; // 1 %
    uint256 public communityShare = maxSupply * communityFee / HUNDRED_PERCENTAGE;
    uint256 public tradeFee = 3; // 0.3%
    uint256 public totalToBeSold = maxSupply - platformShare - communityShare;
    address public owner = makeAddr("owner");
    address public community = makeAddr("community");
    address public protocol = makeAddr("protocol");
    address public router = makeAddr("router");
    address public feeReceiver = makeAddr("feeReceiver");

    function setUp() public {
        LaunchboxExchange exchangeImpl = new LaunchboxExchange();
        exchange = LaunchboxExchange(payable(Clones.clone(address(exchangeImpl))));
        erc20 = new ERC20Mock();
        erc20.mint(address(exchange), totalToBeSold);
        erc20.mint(protocol, platformFee);
        erc20.mint(community, communityShare);
        exchange.initialize(address(erc20), feeReceiver, tradeFee, maxSupply, marketCapThreshold, router);
    }
}
