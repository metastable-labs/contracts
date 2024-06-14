pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20("MOCK", "MOCK") {
    function mint(address _receiver, uint256 _amount) public {
        _mint(_receiver, _amount);
    }
}