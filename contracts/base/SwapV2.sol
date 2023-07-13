// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Address.sol";

abstract contract SwapV2{

    address WETH;

    function getUniswapV2Pair() public view virtual returns(IUniswapV2Pair);
    function getUniswapV2Router02() public view virtual returns(IUniswapV2Router02);

    constructor(address WETH_) {
        WETH = WETH_;
    }

    function needAmount(uint256 amount0) external view returns(uint amount) {
        bool isToken0 = WETH == getUniswapV2Pair().token0();
        (uint reserve0, uint reserve1,) = getUniswapV2Pair().getReserves();
        amount = (isToken0 ? reserve1 * amount0 / reserve0 : reserve0 * amount0/ reserve1);
    }

    function _addLiquidityEth(uint256 amount0, function(IERC20, uint) obtainingFunds) internal returns (uint , uint , uint ) {
        bool isToken0 = WETH == getUniswapV2Pair().token0();
        address token1 = isToken0 ?  getUniswapV2Pair().token1() : getUniswapV2Pair().token0();
        (uint reserve0, uint reserve1,) = getUniswapV2Pair().getReserves();
        uint amount1 = (isToken0 ? reserve1 * amount0 / reserve0 : reserve0  * amount0 / reserve1);

        obtainingFunds(IERC20(token1), amount1);
        
        IERC20(token1).approve(address(getUniswapV2Router02()), amount1);
        
        return getUniswapV2Router02().addLiquidityETH{value : amount0}(
            token1,
            amount1,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    function _removeLiquidity(uint liquidity) internal {
        address token1 = WETH == getUniswapV2Pair().token0() ?  getUniswapV2Pair().token1() : getUniswapV2Pair().token0();
        getUniswapV2Pair().approve(address(getUniswapV2Router02()), liquidity);
        getUniswapV2Router02().removeLiquidityETH(
            token1,
            liquidity,
            0,
            0,
            msg.sender,
            block.timestamp
        );
    }
}