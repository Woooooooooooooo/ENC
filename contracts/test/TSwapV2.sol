// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../base/SwapV2.sol";

contract TSwapV2 is SwapV2{

    IUniswapV2Pair uniswapV2Pair;
    IUniswapV2Router02 uniswapV2Router02;

    constructor() SwapV2(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6) {
        uniswapV2Pair = IUniswapV2Pair(0x16Fb57D796e8c4224aD30c343605F312271B6c57);
        uniswapV2Router02 = IUniswapV2Router02(0xEfF92A263d31888d860bD50809A8D171709b7b1c);
    }

    event AddLiquidity(uint amountA, uint amountB, uint liquidity);

    function getUniswapV2Pair() public view override returns(IUniswapV2Pair) {
        return uniswapV2Pair;
    }
    function getUniswapV2Router02() public view override returns(IUniswapV2Router02) {
        return uniswapV2Router02;
    }

    function obtainingFunds(IERC20 token, uint amount) internal {
        token.transferFrom(msg.sender, address(this), amount);
    }

    function addLiquidity() external payable {
       (uint amountA, uint amountB, uint liquidity) = _addLiquidityEth(msg.value, obtainingFunds);
        emit AddLiquidity( amountA,  amountB,  liquidity);
   }

   function removeLiquidity(uint liquidity) external {
        _removeLiquidity(liquidity);
   }

}