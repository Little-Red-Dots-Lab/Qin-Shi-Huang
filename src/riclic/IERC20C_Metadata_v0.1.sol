// SPDX-License-Identifier: MIT
// Creator: Ric Li C (Twitter @Ric_Li_C)
// Ric Li C's solution of IERC20 meta data, version 0.1
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.18;

import {IERC20C} from "./IERC20C_v0.1.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20CMetadata is IERC20C {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}
