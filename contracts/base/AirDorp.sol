// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "./BaseParam.sol";

abstract contract AirDorp is BaseParam{

    using EnumerableMap for EnumerableMap.UintToUintMap;

    uint public aTotal;
    EnumerableMap.UintToUintMap private _aProportion;
    mapping(address => uint) public airDorpReward;

    constructor() {
        aTotal = 25000000 * _baseProportion;
        _aProportion.set(1000 * _baseProportion, 600);
        _aProportion.set(2000 * _baseProportion, 800 - 600);
    }

    function _sendReward(address to, uint amount, bool isbonus) internal virtual;

    function _airDorp(uint amount) internal {
        if (aTotal == 0) return; 
        uint rewardProportion;
        uint[] memory keys = _aProportion.keys();
        for (uint i; i < keys.length; i++) {
            if (amount >= keys[i]) {
                rewardProportion += _aProportion.get(keys[i]);
            }
        }
        if (rewardProportion == 0) return;
        uint reward = amount * rewardProportion / _baseProportion;
        if (reward > aTotal) reward = aTotal;
        aTotal -= reward;
        airDorpReward[msg.sender] += reward;
    }

    function getAirDorpReward() external {
        uint reward = airDorpReward[msg.sender];
        require(reward > 0, 'reward < 0');
        airDorpReward[msg.sender] = 0;
        _sendReward(msg.sender, reward, false);
    }

}