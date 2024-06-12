// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IL1MigrateLiquidity} from "../interfaces/IL1MigrateLiquidity.sol";

// Check if there's a pool for this token on uniswap
// check what version of uniswap the pool is available - V1 or V2
// get balance of lp token for connected address
// withdraw liquidity from uniswap
// take a % of token A and token B as fees (0.05% each)
// bridge tokens using the base standard L1 bridge, Token A and Token B from Ethereum to Base and send it to the user

contract l1MigrateLiquidity is IL1MigrateLiquidity {}
