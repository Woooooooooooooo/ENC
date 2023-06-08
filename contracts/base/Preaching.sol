// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

abstract contract Preaching {

    using EnumerableMap for EnumerableMap.UintToUintMap;

    uint depth;
    EnumerableMap.UintToUintMap experience;
    
    struct Player{
        uint level;
        uint totalInvested;
        uint totalplayer;
        uint rewardGratitude;
        uint rewardPayedGratitude;
        uint rewardPartition;
        uint rewardPayedPartition;
        address referral;
        address[] referrals;
    }

    mapping(address => Player) public players;

    event RewardGratitude(address indexed account, uint amount);
    event RewardPartition(address indexed account, uint amount);

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
        depth = depth_;
        experience.set(20000e18, 2);
        experience.set(50000e18, 4);
        experience.set(100000e18, 8);
        experience.set(200000e18, 16);
        experience.set(500000e18, 32);
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
        for (uint i; i < depth; i++) {
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
        if (referrals.length <= 1) {
            return;
        }
        for(uint i; i < referrals.length; i++) {
            totalInvested = players[referrals[i]].totalInvested;
            if (totalInvested > max)  max = totalInvested;
            total += totalInvested;
        }
        total -= max;
        players[account].level = _grading(total);
    }

    function _grading(uint amount) internal view returns(uint level_){
        uint256[] memory keys = experience.keys();
        for (uint i; i < keys.length; i++) {
            if (amount >= keys[i]) {
                level_ += experience.get(keys[i]);
            }
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

    function getRewardPartition() public {
        uint256 reward = players[msg.sender].rewardPartition;
        if (reward > 0) {
            players[msg.sender].rewardPartition = 0;
            players[msg.sender].rewardPayedPartition += reward;
            _sendReward(msg.sender, reward);
            emit RewardPartition(msg.sender, reward);
        }
    }

}