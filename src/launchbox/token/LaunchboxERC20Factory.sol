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

    address payable platformFeeAddress;

    uint256 tokenId; // auto incremental

    uint256 private constant PRECISION_DEGREE = 18;
    uint256 private constant MAX_TOKEN_DECIMALS = 18;
    uint256 private constant PRECISION = 1 * (10 ** PRECISION_DEGREE);
    uint256 private constant HUNDRED_PERCENTAGE = 100 * (10 ** PRECISION_DEGREE);

    TokenInfo[] public tokens; // list of tokens
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
     * @param _decimals    ERC20 decimals
     * @return Address of the newly deployed LaunchboxERC20 token and  newly deployed exchange contract.
     */
    function createToken(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply)
        external
        returns (address, address)
    {
        // calculate platform fee
        uint256 feeFromTokenSupply = _calculatePlatformFee(_totalSupply);
        uint256 tokenSupplyAfterFee = _totalSupply - feeFromTokenSupply;
        // deploy exchange contract
        address exchangeContract = 0xF175520C52418dfE19C8098071a252da48Cd1C19;
        // deploy clone
        address newLaunchboxERC20 = Clones.clone(launchboxERC20Implementation);
        // initialize clone
        LaunchboxERC20(newLaunchboxERC20).initialize(
            _name, _symbol, _decimals, tokenSupplyAfterFee, feeFromTokenSupply, exchangeContract, platformFeeAddress
        );
        _addTokenstoMapping(msg.sender, newLaunchboxERC20, exchangeContract);
        emit LaunchboxERC20Created(msg.sender, newLaunchboxERC20);
        return (newLaunchboxERC20, exchangeContract);
    }

    function modifyPlatformFeePercentage(uint256 _percentage) external onlyOwner {
        platformFeePercentage = _percentage;
    }

    function modifyPlatformFeeAddressRecipient(address _newFeeAddress) external onlyOwner {
        platformFeeAddress = payable(_newFeeAddress);
    }

    // getter methods
    function getTokenId() external view returns (uint256) {
        return tokenId;
    }

    function getTokenByID(uint256 _tokenId) external view returns (TokenInfo memory) {
        TokenInfo memory _token = tokenMapping[_tokenId];

        return _token;
    }

    function getTokens() external view returns (TokenInfo[] memory) {
        return tokens;
    }

    function getTokensbyDeployer(address _deployer) external view returns (TokenInfo[] memory) {
        // count the number of tokens that a particular address has deployed
        uint256 tokenCount = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i].deployer == _deployer) {
                tokenCount++;
            }
        }

        // Create an array to hold the tokens deployed by the specified address
        TokenInfo[] memory result = new TokenInfo[](tokenCount);
        uint256 index = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i].deployer == _deployer) {
                result[index] = tokens[i];
                index++;
            }
        }

        return result;
    }

    // internal methods
    function _addTokenstoMapping(address _tokenAddress, address _deployer, address _exchangeContract) internal {
        tokens.push(TokenInfo(_tokenAddress, _deployer, _exchangeContract));
        uint256 newTokenId = tokens.length - 1;
        tokenMapping[newTokenId] = tokens[newTokenId];
        ownerMapping[newTokenId] = _deployer;
        tokenId++;
    }

    function _calculatePlatformFee(uint256 _totalSupply) internal returns (uint256) {
        require(platformFeePercentage <= HUNDRED_PERCENTAGE, "Percentage cannot exceed 100%");
        return (_totalSupply * platformFeePercentage) / HUNDRED_PERCENTAGE;
    }
}
