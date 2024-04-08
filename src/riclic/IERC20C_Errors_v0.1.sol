// SPDX-License-Identifier: MIT
// Creator: Ric Li C (Twitter @Ric_Li_C)
// Ric Li C's solution of IERC20 errors, version 0.1
// Revised based on OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC6093.sol)

pragma solidity ^0.8.18;

/**
 * @dev Standard ERC20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC20 tokens.
 */
interface IERC20CErrors {
    error ERC20C_ExceedFairLaunchLimit(
        uint256 balance,
        uint256 tokenAmount,
        uint256 fairLaunchLimit
    );
    error ERC20C_LiquidityNotReady(address account);
    error ERC20C_ExceedAccountLimit(
        address account,
        uint256 balance,
        uint256 tokenAmount,
        uint256 accountLimit
    );
    error ERC20C_TokenAmountTooLow(address account, uint256 ethAmount);
    error ERC20C_InsufficientTokenAmount(
        address account,
        uint256 tokenAmount,
        uint256 contractTokenBalance
    );
    error ERC20C_EthAmountTooLow(address account, uint256 tokenAmount);
    error ERC20C_InsufficientEthAmount(
        address account,
        uint256 ethAmount,
        uint256 contractBalance
    );
    error ERC20C_TransferEthFailed(address account, uint256 ethAmount);

    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20C_InsufficientBalance(
        address sender,
        uint256 balance,
        uint256 needed
    );

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20C_InsufficientAllowance(
        address spender,
        uint256 allowance,
        uint256 needed
    );

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20C_InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20C_InvalidSpender(address spender);
}
