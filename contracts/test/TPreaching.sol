// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../base/Preaching.sol";

contract TPreaching is Preaching{

    mapping(address => uint) public balance;
    mapping(address => uint) public reward;

    constructor() Preaching(7) {

    }

    function _invested(address account) internal view override returns(uint) {
        return balance[account];
    }
    function _sendReward(address to, uint amount, bool isbonus) internal override {
        reward[to] += amount;
    }

    function add(uint amount) external changes{
        balance[msg.sender] += amount;
    }

    function sub(uint amount) external changes{
        balance[msg.sender] -= amount;
    }

    function bonus(uint amount) external {
        _bonus(amount);
    }
    

}