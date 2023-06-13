// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

import "./base/SwapV2.sol";
import "./base/Preaching.sol";
import "./base/StakingRewards.sol";

contract ENC is StakingRewards, Preaching, SwapV2{

    using SafeERC20 for IERC20;
    using EnumerableMap for EnumerableMap.UintToUintMap;


    uint private immutable _baseProportion = 10000;

    struct Info {
        uint addLiquidityProportion;
        IUniswapV2Pair uniswapV2Pair;
        IUniswapV2Router02 uniswapV2Router02;
    }

    Info public info;
    uint private _total;
    
    mapping(uint => uint) public proportion;
    mapping(uint => uint) public lockDate;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(uint => EnumerableMap.UintToUintMap)) private _lockLog;
    mapping(address => mapping(uint => uint)) private _lockLiquidity;

    constructor() SwapV2(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6) Preaching(7) {
        proportion[3] = 10700;
        proportion[5] = 10800;
        lockDate[5] = 5 * 365 days;
        lockDate[3] = 3 * 365 days;
        info.uniswapV2Pair = IUniswapV2Pair(0x16Fb57D796e8c4224aD30c343605F312271B6c57);
        info.uniswapV2Router02 = IUniswapV2Router02(0xEfF92A263d31888d860bD50809A8D171709b7b1c);
    }

    function _invested(address account) internal view override returns(uint) {
        return _balances[account];
    }
    function _sendReward(address to, uint amount, bool isbonus) internal override(Preaching, StakingRewards) {
        payable(to).transfer(amount);
        if (isbonus) _bonus(amount);
    }

    function getUniswapV2Pair() public view override returns(IUniswapV2Pair) {
        return info.uniswapV2Pair;
    }
    function getUniswapV2Router02() public view override returns(IUniswapV2Router02) {
        return info.uniswapV2Router02;
    }

    function _obtainingFunds(IERC20 token, uint amount) internal {
        token.transferFrom(msg.sender, address(this), amount);
    }

    function _transferFrom(IERC20 token, address from, address to, uint amount) internal {
        
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function totalSupply() external view override returns (uint256) {
        return _total;
    }

    function exit() public override {
        withdraw();
        getReward();
    }

    function withdraw() public changes {
        (uint unlockAmonut3, uint stakeAmount3, uint liquidity3)= _sumUnlockAmount(3, msg.sender);
        (uint unlockAmonut5, uint stakeAmount5, uint liquidity5) = _sumUnlockAmount(5, msg.sender);
        _removeLiquidity(liquidity3 + liquidity5);
        _withdraw(stakeAmount3 + stakeAmount5);
        payable(msg.sender).transfer((unlockAmonut5 + unlockAmonut3) * (_baseProportion - info.addLiquidityProportion) / _baseProportion);
        _balances[msg.sender] -= unlockAmonut5 + unlockAmonut3;
        _total -= unlockAmonut5 + unlockAmonut3;
    }

    function _sumUnlockAmount(uint year, address account) internal returns (uint unlockAmount, uint stakeAmount, uint liquidity) {
        EnumerableMap.UintToUintMap storage map = _lockLog[account][year];
        uint[] memory keys = map.keys();
        for (uint i; i < keys.length; i++) {
            if (keys[i] <= block.timestamp) {
                unlockAmount += map.get(keys[i]);
                stakeAmount += map.get(keys[i]) * proportion[year] / _baseProportion;
                liquidity += _lockLiquidity[account][keys[i]];
                delete _lockLiquidity[account][keys[i]];
                map.remove(keys[i]);
            }
        }
    }

    function stake(uint year, address referral) external payable changes {
        require(!_lockLog[msg.sender][year].contains(block.timestamp), "error");
        uint256 amount = msg.value;
        _binding(referral, msg.sender);
        (, , uint liquidity) =  _addLiquidityEth(amount * info.addLiquidityProportion / _baseProportion, _obtainingFunds);
        _stake(amount * proportion[year] / _baseProportion);
        _total += amount; 
        _balances[msg.sender] += amount;
        _lockLog[msg.sender][year].set(block.timestamp + lockDate[year], amount);
        _lockLiquidity[msg.sender][block.timestamp] = liquidity;
    }

}