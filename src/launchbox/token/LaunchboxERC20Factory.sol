// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {LaunchboxERC20} from "./LaunchboxERC20.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {ILaunchboxERC20Factory} from "./interface/ILaunchboxERC20Factory.sol";

/**
 * @title LaunchboxERC20Factory
 * @notice Factory contract for creating, deploying and managing LaunchboxERC20 tokens.
 * @author  @njokuScript
 */
contract LaunchboxERC20Factory is ILaunchboxERC20Factory, Ownable {
    /**
     * @notice Returns the version of the LaunchboxERC20Factory contract
     */
    string public constant version = "1.0.0";
    /**
     * @notice Percentage of token supply to charge as fee
     */
    uint256 public platformFeePercentage;

    uint256 tokenId; // auto incremental

    uint256 private constant PRECISION_DEGREE = 18;
    uint256 private constant MAX_TOKEN_DECIMALS = 18;
    uint256 private constant PRECISION = 1 * (10 ** PRECISION_DEGREE);
    uint256 private constant HUNDRED_PERCENTAGE =
        100 * (10 ** PRECISION_DEGREE);

    TokenInfo[] public token; // list of tokens
    mapping(uint256 => TokenInfo) public tokenMapping; // ID to token data
    mapping(uint256 => address) public ownerMapping; // TokenData ID => Owner

    /**
     * @notice Address of the LaunchboxERC20 implementation on this chain.
     */
    address public immutable launchboxERC20Implementation;

    /**
     * @notice constructor
     * @param _implementation Address of the LaunchboxERC20 implementation.
     */
    constructor(address _implementation) {
        if (_implementation == address(0)) revert ImplementationCannotBeNull();
        launchboxERC20Implementation = _implementation;
    }

    /**
     * @dev override renounce ownership to be impossible
     */
    function renounceOwnership() public payable override onlyOwner {
        revert();
    }

    /**
     * @notice Deploys a new LaunchboxERC20 token clone with specified parameters.
     * @param _name Name for the new token.
     * @param _symbol Symbol for the new token.
     * @return Address of the newly deployed LaunchboxERC20 token.
     * @param _decimals    ERC20 decimals
     */
    function createToken(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) external returns (address) {
        // calculate platform fee
        // deploy bonding contract
        // deploy clone
        // address newSuperERC20 = Clones.clone(SuperMigrateErc20);
        // initialize clone
        // SuperMigrateERC20(newSuperERC20).initialize(BRIDGE, _remoteToken, _name, _symbol, _decimals);
        // emit SuperMigrateERC20Created(_remoteToken, newSuperERC20, msg.sender);
        // return
    }

    function modifyPlatformFeePercentage(
        uint256 percentage
    ) external onlyOwner {
        platformFeePercentage = percentage;
    }

    // getter methods
    function getTokenId() external view returns (uint256) {
        return tokenId;
    }

    function getTokenByID(
        uint256 _tokenId
    ) external view returns (TokenInfo memory) {
        TokenInfo memory _token = tokenMapping[_tokenId];

        return _token;
    }

    function getTokens() external view returns (TokenInfo[] memory) {
        return token;
    }
}
