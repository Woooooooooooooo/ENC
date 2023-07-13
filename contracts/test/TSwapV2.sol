// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../base/SwapV2.sol";

contract TSwapV2 is SwapV2{

    IUniswapV2Pair uniswapV2Pair;
    IUniswapV2Router02 uniswapV2Router02;

    constructor() SwapV2(0x840f3c7e78b3F642fc5Be7BC9E866D660b0c549F) {
        uniswapV2Pair = IUniswapV2Pair(0x4229291b1c1EF8664249ddE88F6cF4dB651684cC);
        uniswapV2Router02 = IUniswapV2Router02(0x95e2afe9d2A3Af21762A6C619b70836626B74c19);
    }

    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
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
       (uint amountA, uint amountB, uint liquidity) = _addLiquidityEth(msg.value / 20, obtainingFunds);
        emit AddLiquidity( amountA,  amountB,  liquidity);
   }

   function removeLiquidity(uint liquidity) external {
        _removeLiquidity(liquidity);
   }

}