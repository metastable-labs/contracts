pragma solidity ^0.8.20;


import {Test, console} from "forge-std/Test.sol";
import {LaunchboxFactory} from "../../src/launchbox/token/LaunchboxFactory.sol";
import {LaunchboxERC20} from "../../src/launchbox/token/LaunchboxERC20.sol";
import {LaunchboxExchange} from "../../src/launchbox/exchange/LaunchboxExchange.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

contract LaunchboxERC20Base is Test {
    LaunchboxERC20 public erc20;
    address public factory = makeAddr("factory");
    address public exchangeImplementation;

    function setUp() public {
        LaunchboxERC20 erc20Implementation = new LaunchboxERC20();
        erc20 = LaunchboxERC20(Clones.clone(address(erc20Implementation)));
        exchangeImplementation = address(new LaunchboxExchange());
    }
}