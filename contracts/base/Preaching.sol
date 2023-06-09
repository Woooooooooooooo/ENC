// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

abstract contract Preaching {

    using EnumerableMap for EnumerableMap.UintToUintMap;

    EnumerableMap.UintToUintMap experience;
    
    struct Info {
        uint depth;
        uint[] inviteProportion;
        uint baseProportion;
        uint gratitudeProportion;
        mapping(uint => uint) levelProportion;
    }

    Info public pInfo;

    struct Player{
        uint level;
        uint totalInvested;
        uint totalplayer;
        uint rewardGratitude;
        uint rewardPayedGratitude;
        uint rewardLevel;
        uint rewardPayedLevel;
        uint rewardInvite;
        uint rewardPayedInvite;
        address referral;
        address[] referrals;
    }

    mapping(address => Player) public players;

    event RewardGratitude(address indexed account, uint amount);
    event RewardStar(address indexed account, uint amount);
    event RewardInvite(address indexed account, uint amount);

    modifier changes() {
        uint beforeInvested = _invested(msg.sender);
        _;
        uint afterInvested = _invested(msg.sender);
        if (beforeInvested < afterInvested) {
            _updateReferralInvested(msg.sender, afterInvested - beforeInvested, true);
        }
        if (beforeInvested > afterInvested) {
            _updateReferralInvested(msg.sender, beforeInvested - afterInvested, false);
        }
    }

    constructor(uint depth_) {
        pInfo.depth = depth_;
        pInfo.gratitudeProportion = 100;
        pInfo.baseProportion = 10000;
        pInfo.inviteProportion.push(2500);
        pInfo.inviteProportion.push(1500);
        experience.set(20000e18, 2);
        experience.set(50000e18, 4);
        experience.set(100000e18, 8);
        experience.set(200000e18, 16);
        experience.set(500000e18, 32);
        pInfo.levelProportion[2] = 200;
        pInfo.levelProportion[4] = 400;
        pInfo.levelProportion[8] = 600;
        pInfo.levelProportion[16] = 800;
        pInfo.levelProportion[32] = 1000;
    }

    function _invested(address account) internal view virtual returns(uint);
    function _sendReward(address to, uint amount) internal virtual;

    function _binding(address referral, address account) internal {
        if (referral == address(0) 
            || account == address(0)
            || players[account].referral != address(0)
            || players[account].totalInvested != 0
            ) {
            return;
        }
        players[account].referral = referral;
        players[referral].referrals.push(account);
    }

    function _updateReferralInvested(address account, uint amount, bool increase) internal {
        for (uint i; i < pInfo.depth; i++) {
            if(account == address(0)) return;
            if (increase) {
                players[account].totalInvested += amount;
            } else {
                players[account].totalInvested -= amount;
            }
            _updateLevel(account);
            account = players[account].referral;
        }
    }

    function _updateLevel(address account) internal {
        uint total; uint max; uint totalInvested;
        address[] memory referrals = players[account].referrals;
        for(uint i; i < referrals.length; i++) {
            totalInvested = players[referrals[i]].totalInvested;
            if (totalInvested > max)  max = totalInvested;
            total += totalInvested;
        }
        total -= max;
        if (total == 0) {
            return;
        }
        players[account].level = _grading(total);
    }

    function _grading(uint amount) internal view returns(uint level_){
        uint256[] memory keys = experience.keys();
        for (uint i; i < keys.length; i++) {
            if (amount >= keys[i] && level_ < experience.get(keys[i])) {
                level_ = experience.get(keys[i]);
            }
        }
    }

    //  pInfo.depth = depth_;
    //     pInfo.baseProportion = 10000;
    //     pInfo.inviteProportion.push(2500);
    function _bonus(uint amount) internal {
       _bonusInvite(amount);
       _bonusLevel(amount);
    }

    function _bonusLevel(uint amount) internal {
        address addr = msg.sender;
        uint level = players[addr].level;
        uint invested;
        uint gratitude = 5;
        for (uint i; i < pInfo.depth; i++) {
            invested = players[addr].totalInvested;
            addr = players[addr].referral;
            if (addr == address(0)) return;
            if (_isInvestedMax(players[addr].referrals, invested)) continue;
            if (players[addr].level == level && gratitude > 0) {
                players[addr].rewardGratitude += amount * pInfo.gratitudeProportion / pInfo.baseProportion;
                gratitude--; 
            }
            if (players[addr].level > level) {
                level = players[addr].level;
                players[addr].rewardLevel += amount * pInfo.levelProportion[level] / pInfo.baseProportion;
            } 
            
        }
    }

    function _isInvestedMax(address[] storage account, uint amount) internal view returns(bool) {
        for (uint i; i < account.length; i++) {
            if (players[account[i]].totalInvested > amount) {
                return false;
            }
        }
        return true;
    }

    function _bonusInvite(uint amount) internal {
        address addr = msg.sender;
        uint income;
        for (uint i; i < pInfo.inviteProportion.length; i++) {
            addr = players[addr].referral;
            if(addr == address(0)) return;
            income = amount * pInfo.inviteProportion[i] / pInfo.baseProportion;
            if (_invested(msg.sender) >= _invested(addr)) income = income *  _invested(addr) / _invested(msg.sender);
            players[addr].rewardInvite += income;
        }
    }

    function getRewardGratitude() public {
        uint256 reward = players[msg.sender].rewardGratitude;
        if (reward > 0) {
            players[msg.sender].rewardGratitude = 0;
            players[msg.sender].rewardPayedGratitude += reward;
            _sendReward(msg.sender, reward);
            emit RewardGratitude(msg.sender, reward);
        }
    }

    function getRewardStar() public {
        uint256 reward = players[msg.sender].rewardLevel;
        if (reward > 0) {
            players[msg.sender].rewardLevel = 0;
            players[msg.sender].rewardPayedLevel += reward;
            _sendReward(msg.sender, reward);
            emit RewardStar(msg.sender, reward);
        }
    }

    function getRewardInvite() public {
        uint256 reward = players[msg.sender].rewardInvite;
        if (reward > 0) {
            players[msg.sender].rewardInvite = 0;
            players[msg.sender].rewardPayedInvite += reward;
            _sendReward(msg.sender, reward);
            emit RewardInvite(msg.sender, reward);
        }
    }

}