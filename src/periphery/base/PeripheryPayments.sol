// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IPeripheryPayments.sol";
import "../interfaces/external/IWTC.sol";

import "../libraries/TransferHelper.sol";

import "./PeripheryImmutableState.sol";

abstract contract PeripheryPayments is
    IPeripheryPayments,
    PeripheryImmutableState
{
    receive() external payable {
        require(msg.sender == WTC, "Not WTC");
    }

    /// @inheritdoc IPeripheryPayments
    function unwrapWTC(
        uint256 amountMinimum,
        address recipient
    ) public payable override {
        uint256 balanceWTC = IWTC(WTC).balanceOf(address(this));
        require(balanceWTC >= amountMinimum, "Insufficient WTC");

        if (balanceWTC > 0) {
            IWTC(WTC).withdraw(balanceWTC);
            TransferHelper.safeTransferTC(recipient, balanceWTC);
        }
    }

    /// @inheritdoc IPeripheryPayments
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) public payable override {
        uint256 balanceToken = IERC20(token).balanceOf(address(this));
        require(balanceToken >= amountMinimum, "Insufficient token");

        if (balanceToken > 0) {
            TransferHelper.safeTransfer(token, recipient, balanceToken);
        }
    }

    /// @inheritdoc IPeripheryPayments
    function refundTC() external payable override {
        if (address(this).balance > 0)
            TransferHelper.safeTransferTC(msg.sender, address(this).balance);
    }

    /// @param token The token to pay
    /// @param payer The entity that must pay
    /// @param recipient The entity that will receive payment
    /// @param value The amount to pay
    function pay(
        address token,
        address payer,
        address recipient,
        uint256 value
    ) internal {
        if (token == WTC && address(this).balance >= value) {
            // pay with WTC
            IWTC(WTC).deposit{value: value}(); // wrap only what is needed to pay
            IWTC(WTC).transfer(recipient, value);
        } else if (payer == address(this)) {
            // pay with tokens already in the contract (for the exact input multihop case)
            TransferHelper.safeTransfer(token, recipient, value);
        } else {
            // pull payment
            TransferHelper.safeTransferFrom(token, payer, recipient, value);
        }
    }
}
