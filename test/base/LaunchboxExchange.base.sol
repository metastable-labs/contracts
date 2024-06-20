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
    uint256 public maxSupply = 1_000_000_000 ether;
    uint256 public marketCapThreshold = 100_000 ether;
    uint256 public fee = 100_000_000;
    uint256 public totalToBeSold = maxSupply - fee;
    address public owner = makeAddr("owner");
    address public protocol = makeAddr("protocol");
    address public router = makeAddr("router");

    function setUp() public {
        LaunchboxExchange exchangeImpl = new LaunchboxExchange();
        exchange = LaunchboxExchange(payable(Clones.clone(address(exchangeImpl))));
        erc20 = new ERC20Mock();
        erc20.mint(address(exchange), totalToBeSold);
        erc20.mint(address(protocol), fee);
        exchange.initialize(address(erc20), maxSupply, marketCapThreshold, router);
    }
}
