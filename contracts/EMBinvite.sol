// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

import "./base/AirDorp.sol";
import "./base/SwapV2.sol";
import "./base/Preaching.sol";
import "./base/StakingRewards.sol";

contract EMBinvite is StakingRewards, Preaching, SwapV2, AirDorp {
    using SafeERC20 for IERC20;
    using EnumerableMap for EnumerableMap.UintToUintMap;

    struct Info {
        uint addLiquidityProportion;
        IUniswapV2Pair uniswapV2Pair;
        IUniswapV2Router02 uniswapV2Router02;
        uint max;
        uint min;
    }

    address public receiver;
    Info public info;
    uint private _total;
    mapping(uint => uint) _totalYear;

    mapping(uint => uint) public proportion;
    mapping(uint => uint) public lockDate;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(uint => EnumerableMap.UintToUintMap))
        private _lockLog;
    mapping(address => mapping(uint => uint)) private _lockLiquidity;

    constructor(
        address WETH,
        address pair,
        address router,
        address receiver_
    ) SwapV2(WETH) Preaching(50) {
        proportion[3] = 700;
        proportion[5] = 800;
        lockDate[5] = 5 * 365 days;
        lockDate[3] = 3 * 365 days;
        info.uniswapV2Pair = IUniswapV2Pair(pair);
        info.uniswapV2Router02 = IUniswapV2Router02(router);
        info.addLiquidityProportion = 500;
        info.max = 10000e18;
        info.min = 5;
        receiver = receiver_;
    }

    function _invested(address account) internal view override returns (uint) {
        return _balances[account];
    }

    function _sendReward(
        address to,
        uint amount,
        bool isbonus
    ) internal override(Preaching, StakingRewards, AirDorp) {
        payable(to).transfer(amount * 95 / 100);
        payable(receiver).transfer(amount - (amount * 95 / 100));
        if (isbonus) _bonus(amount);
    }

    function getUniswapV2Pair() public view override returns (IUniswapV2Pair) {
        return info.uniswapV2Pair;
    }

    function getUniswapV2Router02()
        public
        view
        override
        returns (IUniswapV2Router02)
    {
        return info.uniswapV2Router02;
    }

    function _obtainingFunds(IERC20 token, uint amount) internal {
        token.transferFrom(msg.sender, address(this), amount);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function totalSupply() public view override returns (uint256) {
        return _total;
    }

    function exit() public override {
        withdraw();
        getReward();
    }

    function withdraw() public changes {
        (
            uint unlockAmonut3,
            uint stakeAmount3,
            uint liquidity3
        ) = _sumUnlockAmount(3, msg.sender);
        (
            uint unlockAmonut5,
            uint stakeAmount5,
            uint liquidity5
        ) = _sumUnlockAmount(5, msg.sender);
        SwapV2._removeLiquidity(liquidity3 + liquidity5);
        StakingRewards._withdraw(stakeAmount3 + stakeAmount5);
        payable(msg.sender).transfer(
            ((unlockAmonut5 + unlockAmonut3) *
                (_baseProportion - info.addLiquidityProportion)) /
                _baseProportion
        );
        _balances[msg.sender] -= unlockAmonut5 + unlockAmonut3;
        _total -= unlockAmonut5 + unlockAmonut3;
        _totalYear[3] -= unlockAmonut3;
        _totalYear[5] -= unlockAmonut5;
    }

    function _sumUnlockAmount(
        uint year,
        address account
    ) internal returns (uint unlockAmount, uint stakeAmount, uint liquidity) {
        EnumerableMap.UintToUintMap storage map = _lockLog[account][year];
        uint[] memory keys = map.keys();
        for (uint i; i < keys.length; i++) {
            if (keys[i] <= block.timestamp) {
                unlockAmount += map.get(keys[i]);
                stakeAmount +=
                    (map.get(keys[i]) * proportion[year]) /
                    _baseProportion;
                liquidity += _lockLiquidity[account][keys[i]];
                delete _lockLiquidity[account][keys[i]];
                map.remove(keys[i]);
            }
        }
    }

    function stake(uint year) external payable changes {
        require(!_lockLog[msg.sender][year].contains(block.timestamp), "error");
        uint256 amount = msg.value;
        require(amount >= info.min && amount <= info.max, "Investment limit");
        AirDorp._airDorp(amount);
        (, , uint liquidity) = SwapV2._addLiquidityEth(
            (amount * info.addLiquidityProportion) / _baseProportion,
            _obtainingFunds
        );
        StakingRewards._stake((amount * proportion[year]) / _baseProportion);
        _total += amount;
        _totalYear[year] += amount;
        _balances[msg.sender] += amount;
        _lockLog[msg.sender][year].set(
            block.timestamp + lockDate[year],
            amount
        );
        _lockLiquidity[msg.sender][block.timestamp] = liquidity;
    }

    function withdrawEth() external onlyOwner {
        payable(msg.sender).transfer(payable(address(this)).balance);
    }

    struct UnLockLog {
        uint unlockTime;
        uint amount;
        uint year;
    }

    function lockLog(
        address account
    ) external view returns (UnLockLog[] memory) {
        uint[] memory keys3 = _lockLog[account][3].keys();
        uint[] memory keys5 = _lockLog[account][5].keys();
        UnLockLog[] memory log = new UnLockLog[](
            _lockLog[account][3].length() + _lockLog[account][5].length()
        );
        uint i;
        for (; i < keys3.length; i++) {
            log[i] = UnLockLog(keys3[i], _lockLog[account][3].get(keys3[i]), 3);
        }
        for (uint j; j < keys5.length; j++) {
            log[j + i] = UnLockLog(
                keys5[j],
                _lockLog[account][5].get(keys5[j]),
                5
            );
        }
        return log;
    }

    struct Data {
        uint reward;
        uint balance;
        uint total;
        uint airDorpReward;
        uint level;
        uint totalplayer;
        uint totalReferral;
        uint stakedSide;
    }

    function viewData(address account) external view returns (Data memory) {
        return
            Data(
                earned(account),
                balanceOf(account),
                players[account].totalInvested,
                airDorpReward[account],
                players[account].level,
                players[account].totalplayer,
                players[account].referrals.length,
                _side(account)
            );
    }

    struct ViweHome {
        uint totalStaked;
        uint totalPayed;
        uint totalBalance;
        uint staked3;
        uint staked5;
        uint stakPayed;
        uint PreachPayed;
    }

    function viewHome() external view returns (ViweHome memory viewHome_) {
        viewHome_.totalStaked = _total;
        viewHome_.totalPayed = payed + preachReward;
        viewHome_.totalBalance = _totalSupply;
        viewHome_.staked3 = _totalYear[3];
        viewHome_.staked5 = _totalYear[5];
        viewHome_.stakPayed = payed;
        viewHome_.PreachPayed = preachReward;
    }
}
