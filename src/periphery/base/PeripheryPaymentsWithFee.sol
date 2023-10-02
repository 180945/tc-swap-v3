// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../core/libraries/LowGasSafeMath.sol";

import "./PeripheryPayments.sol";
import "../interfaces/IPeripheryPaymentsWithFee.sol";

import "../interfaces/external/IWTC.sol";
import "../libraries/TransferHelper.sol";

abstract contract PeripheryPaymentsWithFee is
    PeripheryPayments,
    IPeripheryPaymentsWithFee
{
    using LowGasSafeMath for uint256;

    /// @inheritdoc IPeripheryPaymentsWithFee
    function unwrapWTCWithFee(
        uint256 amountMinimum,
        address recipient,
        uint256 feeBips,
        address feeRecipient
    ) public payable override {
        require(feeBips > 0 && feeBips <= 100);

        uint256 balanceWTC = IWTC(WTC).balanceOf(address(this));
        require(balanceWTC >= amountMinimum, "Insufficient WTC");

        if (balanceWTC > 0) {
            IWTC(WTC).withdraw(balanceWTC);
            uint256 feeAmount = balanceWTC.mul(feeBips) / 10_000;
            if (feeAmount > 0)
                TransferHelper.safeTransferTC(feeRecipient, feeAmount);
            TransferHelper.safeTransferTC(recipient, balanceWTC - feeAmount);
        }
    }

    /// @inheritdoc IPeripheryPaymentsWithFee
    function sweepTokenWithFee(
        address token,
        uint256 amountMinimum,
        address recipient,
        uint256 feeBips,
        address feeRecipient
    ) public payable override {
        require(feeBips > 0 && feeBips <= 100);

        uint256 balanceToken = IERC20(token).balanceOf(address(this));
        require(balanceToken >= amountMinimum, "Insufficient token");

        if (balanceToken > 0) {
            uint256 feeAmount = balanceToken.mul(feeBips) / 10_000;
            if (feeAmount > 0)
                TransferHelper.safeTransfer(token, feeRecipient, feeAmount);
            TransferHelper.safeTransfer(
                token,
                recipient,
                balanceToken - feeAmount
            );
        }
    }
}
