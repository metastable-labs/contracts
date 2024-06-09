// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

interface ILaunchboxERC20Factory {
    // ------------------------------------------------ CUSTOM ERROR ------------------------------------------------
    /**
     * @dev Emitted when the implementation address provided is the zero address.
     */
    error ImplementationCannotBeNull();

    // ------------------------------------------------ EVENTS ------------------------------------------------
    /**
     * @dev Emitted when a new LaunchboxERC20 token is created.
     * @param deployer Address of the deployer.
     */
    event LaunchboxERC20Created(address deployer, address deployedTokenAddress);

    // ------------------------------------------------ CUSTOM TYPES ------------------------------------------------

    struct TokenInfo {
        address tokenAddress; // token address
        address deployer; // Address of the deployer
        address exchangeContract; // Bonding contract tied to the token
    }
}
