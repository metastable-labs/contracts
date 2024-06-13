// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {LaunchboxERC20} from "./LaunchboxERC20.sol";

contract LaunchboxFactory is Ownable(msg.sender) {
    event TokenDeployed(address tokenAddress, address launchboxExchangeAddress);
    event LaunchboxExchangeImplementationUpdated(address newLaunchboxExchangeAddress);
    event TokenImplementationUpdated(address newTokenImplementationAddress);
    event UniswapRouterUpdated(address newRouter);

    address public tokenImplementation;
    address public launchboxExchangeImplementation;
    address public uniswapRouter;
    
    error EmptyTokenImplementation();
    error EmptyLaunchboxExchangeImplementation();
    error EmptyUniswapRouter();

    constructor(address _tokenImplementation, address _launchboxExchangeImplementation, address _uniswapRouter) {
        if(_tokenImplementation == address(0)) revert EmptyTokenImplementation();
        if(_launchboxExchangeImplementation == address(0)) revert EmptyLaunchboxExchangeImplementation();
        if(_uniswapRouter == address(0)) revert EmptyUniswapRouter();
        tokenImplementation = _tokenImplementation;
        launchboxExchangeImplementation = _launchboxExchangeImplementation;
        uniswapRouter = _uniswapRouter;
    }

    function deployToken(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        string memory metadataURI,
        uint256 marketCapThreshold
    ) external returns(address, address) {
        address tokenClone = Clones.clone(tokenImplementation);

        address curveClone = LaunchboxERC20(tokenClone).initialize(
            name,
            symbol,
            maxSupply,
            marketCapThreshold,
            metadataURI,
            launchboxExchangeImplementation,
            uniswapRouter
        );

        emit TokenDeployed(tokenClone, curveClone);
        return (tokenClone, curveClone);
    }

    function setTokemImplementation(address _newTokenImplementation) external onlyOwner {
        if(_newTokenImplementation == address(0)) revert EmptyTokenImplementation();
        tokenImplementation = _newTokenImplementation;
        emit TokenImplementationUpdated(_newTokenImplementation);
    }

    function setLaunchboxExchangeImplementation(address _newLaunchboxExchangeImplementation) external onlyOwner {
        if(_newLaunchboxExchangeImplementation == address(0)) revert EmptyLaunchboxExchangeImplementation();
        launchboxExchangeImplementation = _newLaunchboxExchangeImplementation;
        emit LaunchboxExchangeImplementationUpdated(_newLaunchboxExchangeImplementation);
    }

    function setRouter(address _newRouter) external onlyOwner {
        if(_newRouter == address(0)) revert EmptyUniswapRouter();
        uniswapRouter = _newRouter;
        emit UniswapRouterUpdated(_newRouter);
    }
}
