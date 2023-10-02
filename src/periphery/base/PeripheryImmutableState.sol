// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import {OwnableUpgradeable} from "@openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IPeripheryImmutableState.sol";

/// @title Immutable state
/// @notice Immutable state used by periphery contracts
abstract contract PeripheryImmutableState is
    IPeripheryImmutableState,
    OwnableUpgradeable
{
    /// @inheritdoc IPeripheryImmutableState
    address public override factory;
    /// @inheritdoc IPeripheryImmutableState
    address public override WTC;

    function __PeripheryImmutableState_init(
        address _factory,
        address _WTC
    ) internal initializer {
        __Ownable_init();
        //
        factory = _factory;
        WTC = _WTC;
    }

    function setWTC(address WTCArg) external onlyOwner {
        WTC = WTCArg;
    }
}
