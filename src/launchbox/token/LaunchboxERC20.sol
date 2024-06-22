// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import {LaunchboxExchange} from "../exchange/LaunchboxExchange.sol";

contract LaunchboxERC20 is ERC20Upgradeable {
    event TokenInitialized(
        uint256 supplyToBeSold,
        address platformFeeReceiver,
        uint256 platformFee,
        address communityShareReceiver,
        uint256 communityShare
    );
    string public metadataURI;
    address payable public launchboxExchange;

    struct InitializeParams {
        string _name;
        string _symbol;
        string _metadataURI;
        uint256 _tradeFee;
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
        // initialize ERC20 contract
        __ERC20_init(params._name, params._symbol);

        // ensure the metadata URI is not empty
        if (bytes(params._metadataURI).length == 0) {
            revert MetadataEmpty();
        }

        // enure the token supply is not zero
        if (params._tokenSupplyAfterFee == 0) {
            revert CannotSellZeroTokens();
        }

        // set state
        metadataURI = params._metadataURI;

        // transfer fees
        _transferPlatformFee(params._platformFee, params._platformFeeAddress);
        _transferCommunityShare(params._communitySupply, params._communityTreasuryOwner);

        // deploy exchange contract
        launchboxExchange = _deployExchange(params);
        emit TokenInitialized(params._tokenSupplyAfterFee, params._platformFeeAddress, params._platformFee, params._communityTreasuryOwner, params._communitySupply);
        return launchboxExchange;
    }

    function _transferPlatformFee(uint256 _platformFee, address _platformFeeAddress) internal {
        // transfer platform fee
        if (_platformFee != 0) {
            if (_platformFeeAddress == address(0)) {
                revert PlatformFeeReceiverEmpty();
            }
            // send platform fee to platform fee address
            _mint(_platformFeeAddress, _platformFee);
        }
    }

    function _transferCommunityShare(uint256 _communitySupply, address _communityTreasuryOwner) internal {
        // transfer community supply fee
        if (_communitySupply != 0) {
            // send community supply
            // unline platform fee receive, community fee receiver will never be zero,
            // as msg.sender is passed in as the receiver
            _mint(_communityTreasuryOwner, _communitySupply);
        }
    }

    function _deployExchange(InitializeParams memory params) internal returns(address payable) {
        address payable _launchboxExchange = payable(Clones.clone(params._launchboxExchangeImplementation));
        // send the balance to the exchange contract
        _mint(_launchboxExchange, params._tokenSupplyAfterFee);

        // initialize the launchbox
        LaunchboxExchange(_launchboxExchange).initialize{value: msg.value}(
            address(this), params._platformFeeAddress, params._tradeFee,  params._tokenSupplyAfterFee, params._marketCapThreshold, params._router
        );
        return _launchboxExchange;
    }
}
