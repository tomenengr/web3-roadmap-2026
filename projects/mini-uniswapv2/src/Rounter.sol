// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./Pair.sol";
import "./Library.sol";

contract Router {
    address public factory;
    address public WETH;

    constructor(address _factory, address _WETH) {
        factory = _factory;
        WETH = _WETH;
    }

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, "expired");
        _;
    }

   function _addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin
) internal returns (uint amountA, uint amountB) {
    // 1. 如果池子根本不存在，立刻帮用户创建
    if (IUniswapV2Factory(factory).getPair(tokenA, tokenB) == address(0)) {
        IUniswapV2Factory(factory).createPair(tokenA, tokenB);
    }
    
    // 2. 获取当前的真实库存（加池子没有方向，统一叫 reserveA 和 reserveB）
    (uint reserveA, uint reserveB) = Library.getReserves(factory, tokenA, tokenB);
    
    // 3. 核心计算逻辑
    if (reserveA == 0 && reserveB == 0) {
        // 情况 A：新池子（或者池子被清空了），没人定过价，用户想加多少就按多少来
        (amountA, amountB) = (amountADesired, amountBDesired);
    } else {
        // 情况 B：老池子，必须严格遵守 K 值比例
        // 尝试按用户的 A 预期，算出需要的 B
        uint amountBOptimal = Library.quote(amountADesired, reserveA, reserveB);
        
        if (amountBOptimal <= amountBDesired) {
            // 如果需要的 B 没超标，那就检查底线：算出来的 B 必须大于用户的滑点容忍下限
            require(amountBOptimal >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
            (amountA, amountB) = (amountADesired, amountBOptimal);
        } else {
            // 如果需要的 B 超标了，说明按照 A 拉满不现实。
            // 我们换个思路，按用户的 B 预期，反向算出需要的 A。
            // 注意 quote 的传参顺序变了：(输入量B, 池子储备B, 池子储备A)
            uint amountAOptimal = Library.quote(amountBDesired, reserveB, reserveA);
            
            // 同样，检查算出来的 A 是不是在预期范围内，并且高于底线
            require(amountAOptimal <= amountADesired, 'UniswapV2Router: EXCESSIVE_A_AMOUNT'); // 其实这一步数学上一定成立，但为了严谨可留可不留
            require(amountAOptimal >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
            
            (amountA, amountB) = (amountAOptimal, amountBDesired);
        }
    }
}
}