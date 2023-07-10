// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.12 <0.9.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";



contract MappingStakingRewards is ReentrancyGuard , Ownable {

    using SafeMath for uint;
    /* ========== STATE VARIABLES ========== */

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration = 2190 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /* ========== VIEWS ========== */

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable(uint time) public view returns (uint256) {
        return time < periodFinish ? time : periodFinish;
    }

    function rewardPerToken(uint time) public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable(time).sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
            );
    }

    function earned(address account, uint time) public view returns (uint256) {
        return _balances[account].mul(rewardPerToken(time).sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

     struct HomeView {
        uint earned;
        uint amount;
        uint earnedMax;
        uint total;
    }

    function homeView(address account) external view returns(HomeView memory homeView_) {
        homeView_.earned = earned(account, block.timestamp);
        homeView_.amount = balanceOf(account);
        homeView_.earnedMax = earned(account, periodFinish) - homeView_.earned;
        homeView_.total = _totalSupply;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    struct Accounts{
        address account;
        uint amount;
    }

    function importAccount(Accounts[] calldata accounts) public nonReentrant updateReward(address(0)){
        for(uint i; i < accounts.length; i++) {
            stake(accounts[i].amount, accounts[i].account);
        }
    }

    function exportAccount(Accounts[] calldata accounts) public nonReentrant updateReward(address(0)){
        for(uint i; i < accounts.length; i++) {
            withdraw(accounts[i].amount, accounts[i].account);
        }
    }

    function stake(uint256 amount, address account) internal virtual  {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Staked(account, amount);
    }

    function withdraw(uint256 amount, address account) internal virtual {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[account] = _balances[account].sub(amount);
        emit Withdrawn(account, amount);
    }

    

    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            payable(msg.sender).transfer(reward);
            emit RewardPaid(msg.sender, reward);
        }
    }


    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward) external updateReward(address(0)) onlyOwner {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    function withdrawEth() external onlyOwner {
        payable(msg.sender).transfer(payable(address(this)).balance);
    }


    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken(block.timestamp);
        lastUpdateTime = lastTimeRewardApplicable(block.timestamp);
        if (account != address(0)) {
            rewards[account] = earned(account, block.timestamp);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);
}
