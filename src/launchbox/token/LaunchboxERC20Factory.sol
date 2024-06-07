// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {LaunchboxERC20} from "./LaunchboxERC20.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * @title LaunchboxERC20Factory
 * @notice Factory contract for creating, deploying and managing LaunchboxERC20 tokens.
 * @author  @njokuScript
 */
contract LaunchboxERC20Factory {
    /**
     * @notice Returns the version of the LaunchboxERC20Factory contract
     */
    string public constant version = "1.0.0";

    /**
     * @notice Address of the LaunchboxERC20 implementation on this chain.
     */
    address public immutable launchboxERC20Implementation;

    /**
     * @dev Emitted when the implementation address provided is the zero address.
     */
    error ImplementationCannotBeNull();

    /**
     * @dev Emitted when a new LaunchboxERC20 token is created.
     * @param deployer Address of the deployer.
     */
    event LaunchboxERC20Created(address deployer);

    /**
     * @notice constructor
     * @param _implementation Address of the LaunchboxERC20 implementation.
     */
    constructor(address _implementation) {
        if (_implementation == address(0)) revert ImplementationCannotBeNull();
        launchboxERC20Implementation = _implementation;
    }

    /**
     * @notice Deploys a new LaunchboxERC20 token clone with specified parameters.
     * @param _name Name for the new token.
     * @param _symbol Symbol for the new token.
     * @return Address of the newly deployed LaunchboxERC20 token.
     * @param _decimals    ERC20 decimals
     */
    function createToken(string memory _name, string memory _symbol, uint8 _decimals) external returns (address) {
        // calculate platform fee
        // deploy bonding contract
        // deploy clone
        // address newSuperERC20 = Clones.clone(SuperMigrateErc20);
        // initialize clone
        // SuperMigrateERC20(newSuperERC20).initialize(BRIDGE, _remoteToken, _name, _symbol, _decimals);
        // emit SuperMigrateERC20Created(_remoteToken, newSuperERC20, msg.sender);
        // return
    }
}
