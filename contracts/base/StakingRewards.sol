// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IStakingRewards.sol";

abstract contract StakingRewards is IStakingRewards, ReentrancyGuard, Ownable{

    /* ========== STATE VARIABLES ========== */
    uint256 periodFinish = 0;
    uint256 public rewardRate = 1;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public payed;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    

    /* ========== CONSTRUCTOR ========== */


    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        uint oldTotal = _totalSupply;
        uint oldRate = rewardRate;

        _;

        uint newRate = rewardRate;
        uint newTotal = _totalSupply;
        if (oldTotal == newTotal && oldRate == newRate) {
            return;
        }
        if (periodFinish == 0) {
            periodFinish = 300000000e18 / oldRate / newTotal + block.timestamp;
        } else {
            periodFinish = (periodFinish - block.timestamp) * oldRate * oldTotal / newRate / newTotal + block.timestamp;
        }
    }



    /* ========== EVENTS ========== */

    event RewardRateUpdate(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);

    /* ========== VIEWS ========== */

    function _sendReward(address to, uint amount) internal virtual;

    function totalSupply() external view virtual returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view virtual returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored + ((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate);
    }

    function earned(address account) public view returns (uint256) {
        return _balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account]) / 1e18 + rewards[account];
    }


    /* ========== MUTATIVE FUNCTIONS ========== */

    function _stake(uint256 amount) internal nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply + amount;
        _balances[msg.sender] = _balances[msg.sender] + amount;
        emit Staked(msg.sender, amount);
    }

    function _withdraw(uint256 amount) internal nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply - amount;
        _balances[msg.sender] = _balances[msg.sender] - amount;
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            payed += reward;
            _sendReward(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
        rewardRate = reduceProduction(rewardRate, payed);
    }

    function exit() public virtual {
        _withdraw(_balances[msg.sender]);
        getReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardRate(uint256 rewardRat_) internal updateReward(address(0)) {
        rewardRate = rewardRat_;
        emit RewardRateUpdate(rewardRat_);
    }

    function reduceProduction(uint256 rewardRat_, uint production) internal pure returns(uint) {
        uint[10] memory limit = [uint(3000000e18), 6000000e18, 9000000e18, 12000000e18, 15000000e18, 30000000e18, 60000000e18, 90000000e18, 120000000e18, 200000000e18];
        uint powerNum;
        for (uint i; i < limit.length; i++) {
            if (production / limit[1] > 0) {
                ++powerNum;
            }
        }
        rewardRat_ = rewardRat_ * (7 ** powerNum) / (10 ** powerNum); 
        return rewardRat_;
    }
    
}