// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract Token is ERC20PresetMinterPauser{

    bytes32 public constant BLACKLIST_ROLE = keccak256("BLACKLIST_ROLE");

    constructor(string memory name, string memory symbol, address to) ERC20PresetMinterPauser(name, symbol) {
        _mint(to, 5000000e18);
        _setRoleAdmin(BLACKLIST_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(MINTER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(PAUSER_ROLE, DEFAULT_ADMIN_ROLE);
        _setupRole(DEFAULT_ADMIN_ROLE, to);
        _setupRole(MINTER_ROLE, to);
        _setupRole(PAUSER_ROLE, to);
        
        _revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _revokeRole(MINTER_ROLE, _msgSender());
        _revokeRole(PAUSER_ROLE, _msgSender());
    }

    function setBlackList(address[] calldata acounts) external {
        for (uint i; i < acounts.length; i++) {
            grantRole(BLACKLIST_ROLE, acounts[i]);
        }
    }

    function removeBlackList(address[] calldata acounts) external {
        for (uint i; i < acounts.length; i++) {
            revokeRole(BLACKLIST_ROLE, acounts[i]);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20PresetMinterPauser) {
        require(!hasRole(BLACKLIST_ROLE, from), "on the blacklist");
        super._beforeTokenTransfer(from, to, amount);
    }

}