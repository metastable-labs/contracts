// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import {LaunchboxExchange} from "../exchange/LaunchboxExchange.sol";

contract LaunchboxERC20 is ERC20Upgradeable {
    string public metadataURI;
    address payable public launchboxExchange;

    struct InitializeParams {
        string _name;
        string _symbol;
        string _metadataURI;
        uint256 _tokenSupplyAfterFee;
        uint256 _platformFee;
        uint256 _communitySupply;
        uint256 _marketCapThreshold;
        address _launchboxExchangeImplementation;
        address _platformFeeAddress;
        address _router;
        address _communityTreasuryOwner;
    }

    error MetadataEmpty();
    error CannotSellZeroTokens();
    error PlatformFeeReceiverEmpty();

    constructor() {
        _disableInitializers();
    }

    function initialize(InitializeParams memory params) external payable initializer returns (address) {
        __ERC20_init(params._name, params._symbol);
        if (bytes(params._metadataURI).length == 0) {
            revert MetadataEmpty();
        }
        if (params._tokenSupplyAfterFee == 0) {
            revert CannotSellZeroTokens();
        }

        metadataURI = params._metadataURI;

        launchboxExchange = payable(Clones.clone(params._launchboxExchangeImplementation));
        if (params._platformFee != 0) {
            if (params._platformFeeAddress == address(0)) {
                revert PlatformFeeReceiverEmpty();
            }
            // send platform fee to platform fee address
            _mint(params._platformFeeAddress, params._platformFee);
        }
        if (params._communitySupply != 0) {
            // send community supply
            // unline platform fee receive, community fee receiver will never be zero,
            // as msg.sender is passed in as the receiver
            _mint(params._communityTreasuryOwner, params._communitySupply);
        }
        // send the balance to the exchange contract
        _mint(launchboxExchange, params._tokenSupplyAfterFee);
        LaunchboxExchange(launchboxExchange).initialize(
            address(this), params._tokenSupplyAfterFee, params._marketCapThreshold, params._router
        );
        return launchboxExchange;
    }
}
