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
    error PlatformFeeReceiverEmpty();

    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _metadataURI,
        uint256 _tokenSupplyAfterFee,
        uint256 _platformFee,
        uint256 _communitySupply,
        uint256 _marketCapThreshold,
        address _launchboxExchangeImplementation,
        address _platformFeeAddress,
        address _router,
        address _communityTreasuryOwner
    ) external payable initializer returns (address) {
        __ERC20_init(_name, _symbol);
        if (bytes(_metadataURI).length == 0) {
            revert MetadataEmpty();
        }
        if (_tokenSupplyAfterFee == 0) {
            revert CannotSellZeroTokens();
        }

        metadataURI = _metadataURI;

        launchboxExchange = payable(Clones.clone(_launchboxExchangeImplementation));
        if (_platformFee != 0) {
            if (_platformFeeAddress == address(0)) {
                revert PlatformFeeReceiverEmpty();
            }
            // send platform fee to platform fee address
            _mint(_platformFeeAddress, _platformFee);
        }
        _mint(_communityTreasuryOwner, _communitySupply);
        // send the balance to the exchange contract
        _mint(launchboxExchange, _tokenSupplyAfterFee);
        LaunchboxExchange(launchboxExchange).initialize(
            address(this), _tokenSupplyAfterFee, _marketCapThreshold, _router
        );
        return launchboxExchange;
    }
}
