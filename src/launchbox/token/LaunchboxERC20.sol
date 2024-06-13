// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import {LaunchboxExchange} from "../exchange/LaunchboxExchange.sol";

contract LaunchboxERC20 is ERC20Upgradeable {
    string public metadataURI;
    address payable public launchboxExchange;

    error MetadataEmpty();
    error CannotSellZeroTokens();

    constructor() {
        _disableInitializers();
    }

    function initialize(string memory _name, string memory _symbol, uint256 _maxSupply, uint256 _marketCapThreshold, string memory _metadataURI, address _launchboxExchangeImplementation, address  _uniswapRouter) external initializer returns(address) {
        __ERC20_init(_name, _symbol);
        if(bytes(_metadataURI).length == 0) {
            revert MetadataEmpty();
        }
        if(_maxSupply == 0) {
            revert CannotSellZeroTokens();
        }

        metadataURI = _metadataURI;

        launchboxExchange = payable(Clones.clone(_launchboxExchangeImplementation));
        _mint(launchboxExchange, _maxSupply);
        LaunchboxExchange(launchboxExchange).initialize(address(this), _maxSupply, _marketCapThreshold, _uniswapRouter);
        return launchboxExchange;
    }
}
