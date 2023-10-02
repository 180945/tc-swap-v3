// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of TC
interface IPeripheryPayments {
    /// @notice Unwraps the contract's WTC balance and sends it to recipient as TC.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WTC from users.
    /// @param amountMinimum The minimum amount of WTC to unwrap
    /// @param recipient The address receiving TC
    function unwrapWTC(
        uint256 amountMinimum,
        address recipient
    ) external payable;

    /// @notice Refunds any TC balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundTC() external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;
}
