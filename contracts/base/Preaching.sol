// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "./BaseParam.sol";

abstract contract Preaching is BaseParam{

    using EnumerableMap for EnumerableMap.UintToUintMap;

    EnumerableMap.UintToUintMap experience;
    
    struct PInfo {
        uint depth;
        uint[] inviteProportion;
        uint gratitudeProportion;
        mapping(uint => uint) levelProportion;
    }

    PInfo public pInfo;
    uint preachReward;

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
    event Binding(address indexed referral, address indexed account, uint time);

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
        pInfo.inviteProportion.push(1500);
        pInfo.inviteProportion.push(2500);
        experience.set(20000 * _baseDecimals, 2);
        experience.set(50000 * _baseDecimals, 4);
        experience.set(100000 * _baseDecimals, 8);
        experience.set(200000 * _baseDecimals, 16);
        experience.set(500000 * _baseDecimals, 32);
        pInfo.levelProportion[2] = 200;
        pInfo.levelProportion[4] = 200;
        pInfo.levelProportion[8] = 200;
        pInfo.levelProportion[16] = 200;
        pInfo.levelProportion[32] = 200;
    }

    function _invested(address account) internal view virtual returns(uint);
    function _sendReward(address to, uint amount, bool isbonus) internal virtual;

    function binding(address referral, address account) external {
        require(referral != address(0) && account != address(0) && referral != account, 'param error');
        require(_repeat(referral, account), 'Referral is duplicated');
        players[account].referral = referral;
        players[referral].referrals.push(account);
        players[referral].totalplayer = players[referral].referrals.length;
        emit Binding(referral, account, block.timestamp);
    }

    function _repeat(address referral, address account) internal view returns (bool) {
        for(uint i = 0; i < pInfo.depth; i++) {
            referral = players[referral].referral;
            if (referral == address(0)) return true; 
            if (referral == account) return false;
        }
        return true;
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
        uint total = _side(account);
        if (total == 0) {
            return;
        }
        players[account].level = _grading(total);
    }

    function _side(address account) internal view returns (uint total){
        uint max; uint totalInvested;
        address[] memory referrals = players[account].referrals;
        for(uint i; i < referrals.length; i++) {
            totalInvested = players[referrals[i]].totalInvested;
            if (totalInvested > max)  max = totalInvested;
            total += totalInvested;
        }
        total -= max;
    }

    function _grading(uint amount) internal view returns(uint level_){
        uint256[] memory keys = experience.keys();
        for (uint i; i < keys.length; i++) {
            if (amount >= keys[i] && level_ < experience.get(keys[i])) {
                level_ += experience.get(keys[i]);
            }
        }
    }

    function _bonus(uint amount) internal {
       _bonusInvite(amount);
       _bonusLevel(amount);
    }

    function _bonusLevel(uint amount) internal {
        address addr = msg.sender;
        uint level = players[addr].level;
        uint invested;
        uint gratitude = 5;
        uint residue = 62;
        uint tempLevel;
        for (uint i; i < pInfo.depth; i++) {
            invested = players[addr].totalInvested;
            addr = players[addr].referral;
            if (addr == address(0)) return;
            if (players[addr].level == level && gratitude > 0 && level > 0) {
                players[addr].rewardGratitude += amount * pInfo.gratitudeProportion / _baseProportion;
                gratitude--; 
            } else if (players[addr].level > level) {
                level = players[addr].level;
                tempLevel =  residue & level;
                if (tempLevel == 0) continue;
                residue -= tempLevel;
                players[addr].rewardLevel += amount * _levelShare(tempLevel) / _baseProportion;
            } 
        }
    }

    function _levelShare(uint level_) private view returns (uint proportion) {
        for(uint i = 2; i <= 32; i *= 2) {
            if (level_ & i > 0) {
                proportion += pInfo.levelProportion[i];
            }
        }
    }

    function _bonusInvite(uint amount) internal {
        address addr = msg.sender;
        uint income;
        for (uint i; i < pInfo.inviteProportion.length; i++) {
            addr = players[addr].referral;
            if(addr == address(0)) return;
            income = amount * pInfo.inviteProportion[i] / _baseProportion;
            if (_invested(msg.sender) >= _invested(addr)) income = income *  _invested(addr) / _invested(msg.sender);
            players[addr].rewardInvite += income;
        }
    }

    function getRewardGratitude() public {
        uint256 reward = players[msg.sender].rewardGratitude;
        if (reward > 0) {
            players[msg.sender].rewardGratitude = 0;
            players[msg.sender].rewardPayedGratitude += reward;
            preachReward += reward;
            _sendReward(msg.sender, reward, false);
            emit RewardGratitude(msg.sender, reward);
        }
    }

    function getRewardStar() public {
        uint256 reward = players[msg.sender].rewardLevel;
        if (reward > 0) {
            players[msg.sender].rewardLevel = 0;
            players[msg.sender].rewardPayedLevel += reward;
            preachReward += reward;
            _sendReward(msg.sender, reward, false);
            emit RewardStar(msg.sender, reward);
        }
    }

    function getRewardInvite() public {
        uint256 reward = players[msg.sender].rewardInvite;
        if (reward > 0) {
            players[msg.sender].rewardInvite = 0;
            players[msg.sender].rewardPayedInvite += reward;
            preachReward += reward;
            _sendReward(msg.sender, reward, false);
            emit RewardInvite(msg.sender, reward);
        }
    }

    function getBonus() public {
        getRewardGratitude();
        getRewardInvite();
        getRewardStar();
    }

}