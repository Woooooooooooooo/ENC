// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";


import "../base/StakingRewards.sol";

contract TENC is StakingRewards{

    using SafeERC20 for IERC20;
    using EnumerableMap for EnumerableMap.UintToUintMap;

    uint private immutable _baseProportion = 10000;
    uint private _total;
    IERC20 inputToken;
    IERC20 outputToken;
    
    mapping(uint => uint) public proportion;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(uint => EnumerableMap.UintToUintMap)) private _lockLog;

    constructor() {
        proportion[3] = 10700;
        proportion[5] = 10800;
    }

    function _transferFrom(IERC20 token, address from, address to, uint amount) internal {
       // token.transferFrom(from, to, amount);
    }
    
    function _sendReward(address to, uint amount) internal override{
        _transferFrom(outputToken, address(this), to, amount);
        //TEST
        reward[to] += amount;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function rewardsToken() external view returns (IERC20) {
        return outputToken;
    }

    function totalSupply() external view override returns (uint256) {
        return _total;
    }

    function exit() public override {
        super.exit();
    }

    function withdraw() external{
        (uint unlockAmonut3, uint stakeAmount3)= _sumUnlockAmount(3, msg.sender);
        (uint unlockAmonut5, uint stakeAmount5) = _sumUnlockAmount(5, msg.sender);
        _balances[msg.sender] -= unlockAmonut5 + unlockAmonut3;
        _total -= unlockAmonut5 + unlockAmonut3;
        _transferFrom(inputToken, address(this), msg.sender, unlockAmonut5 + unlockAmonut3);
        _withdraw(stakeAmount3 + stakeAmount5);
    }

    function _sumUnlockAmount(uint year, address account) internal returns (uint unlockAmount, uint stakeAmount) {
        EnumerableMap.UintToUintMap storage map = _lockLog[account][year];
        uint[] memory keys = map.keys();
        for (uint i; i < keys.length; i++) {
            if (keys[i] < block.timestamp) {
                unlockAmount += map.get(keys[i]);
                stakeAmount += map.get(keys[i]) * proportion[year] / _baseProportion;
                map.remove(keys[i]);
            }
        }
    }

    function stake(uint256 amount, uint year) external {
        _total += amount; 
        _balances[msg.sender] += amount;
        require(!_lockLog[msg.sender][year].contains(block.timestamp), "error");
        _lockLog[msg.sender][year].set(block.timestamp, amount);
        _stake(amount * proportion[year] / _baseProportion);
        _transferFrom(inputToken, msg.sender, address(this), amount);
    }

    //TEST
    mapping(address => uint256) public reward;
    
}