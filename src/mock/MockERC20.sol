// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.0;

import '@openzeppelin/contracts/presets/ERC20PresetMinterPauser.sol';

contract MockERC20 is ERC20PresetMinterPauser {
    //
    constructor(string memory name, string memory symbol, uint256 amount) ERC20PresetMinterPauser(name, symbol) {
        _mint(msg.sender, amount);
    }

    function setMinter(address minter) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'MockERC20: must have admin');
        grantRole(MINTER_ROLE, minter);
    }
}
