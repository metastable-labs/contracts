// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC165} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title LaunchboxERC20
 * @author  @njokuScript
 */
contract LaunchboxERC20 is Initializable, ERC20Upgradeable {
    /**
     * @dev Stores the version of the contract like Semantic Versioning (Semver),
     * and fulfills the same requirements for version tracking.
     */
    string public constant version = "1.0.0";

    /// @notice Decimals of the token
    uint8 private DECIMALS;
    /**
     * @notice constructor
     * @dev Disables initializers to prevent the contract from being initialized.
     * ensuring that only proxy instances can be initialized.
     */

    constructor() {
        // disable initializer on implementation contract
        _disableInitializers();
    }

    /**
     * @custom:semver 1.0.0
     *
     * @param _name        ERC20 name.
     * @param _symbol      ERC20 symbol.
     * @param _decimals      ERC20 Decimal.
     * @param _tokenSupply    Amount of Tokens to be minted to the bonding curve contract minus platform fees.
     * @param _platformFee    Amount of tokens to be sent to the LaunchboxPlatform fee collector - usually a % of token total supply
     * @param _exchangeContract    Contract of the bonding curve functions responsible for facilitating the buying and selling of the tokens
     * @param _platformFeeAddress    Address receiving the % of the token supply
     */
    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _tokenSupply,
        uint256 _platformFee,
        address _exchangeContract,
        address _platformFeeAddress
    ) external initializer {
        __ERC20_init(_name, _symbol);
        DECIMALS = _decimals;
        _mint(_exchangeContract, _tokenSupply);
        _mint(_platformFeeAddress, _platformFee);
    }

    /// @dev Returns the number of decimals used to get its user representation.
    /// For example, if `decimals` equals `2`, a balance of `505` tokens should
    /// be displayed to a user as `5.05` (`505 / 10 ** 2`).
    /// NOTE: This information is only used for _display_ purposes: it in
    /// no way affects any of the arithmetic of the contract, including
    /// {IERC20-balanceOf} and {IERC20-transfer}.

    function decimals() public view override returns (uint8) {
        return DECIMALS;
    }
}
