// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.0;

abstract contract BlockContext {
    function _blockTimestamp() internal view virtual returns (uint32) {
        return uint32(block.timestamp);
    }

    function _blockNumber() internal view virtual returns (uint256) {
        return block.number;
    }
}
