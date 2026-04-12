//SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;    

import "./IUniswapv2Pair.sol";

library Library {
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1){
        require(tokenA != tokenB, "invalid tokens");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA); 
        require(token0 != address(0),"error token0");
    }

    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address _pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        _pair = address(
            uint160(
                uint(
                    keccak256(abi.encodePacked(
                        hex'ff',
                        factory,
                        abi.encodePacked(token0, token1),
                        hex'434b986ed0cf4b3fddcef33867ea09389b82f73701e11ae6d9c1061bb2caeff4'
                    ))
                )
            )
        );
    }

    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint112 reserveA, uint112 reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        address pair = pairFor(factory, tokenA, tokenB);
        (uint112 _reserve0, uint112 _reserve1, ) = IUniswapV2Pair(pair).getReserves();
        (reserveA, reserveB) = token0 == tokenA ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
    }

    function quote(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, "invalid input");
        require(reserveIn > 0 && reserveOut > 0, "not enough");
        amountOut = amountIn * reserveOut / reserveIn;
    }

    function getAmountOut(uint amountIn, uint _reserveIn, uint _reserveOut) internal pure returns(uint amountOut){
        require(amountIn > 0, "invalid input");
        require(_reserveIn > 0 && _reserveOut > 0 , "not enough");
        uint fenzi = _reserveOut * amountIn * 997;
        uint fenmu =  _reserveIn * 1000 + amountIn * 997;
        amountOut = fenzi / fenmu;
    }

    function getAmountIn(uint amountOut, uint _reserveIn, uint _reserveOut) internal pure returns(uint amountIn){
        require(amountOut > 0, "invalid input");
        require(_reserveIn > 0 && _reserveOut > 0 , "not enough");
        uint fenzi = _reserveIn * amountOut * 1000;
        uint fenmu = (_reserveOut - amountOut) * 997;
        amountIn = fenzi / fenmu + 1;
    }

    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns(uint[] memory amounts) {
        require(path.length >= 2, "invalid path");
        uint pathLength = path.length;
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < pathLength - 1; i++) {
            (uint _reserveIn, uint _reserveOut) = getReserves(factory, path[i], path[i+1]);
            amounts[i+1] = getAmountOut(amounts[i], _reserveIn, _reserveOut);
        }
    }

    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, "invalid path");
        amounts = new uint[](path.length);
        amounts[path.length - 1] = amountOut;
        for (uint i = path.length - 1; i >0; i--) {
            (uint _reserveIn, uint _reserveOut) = getReserves(factory, path[i-1], path[i]);
            amounts[i-1] = getAmountIn(amounts[i], _reserveIn, _reserveOut); 
        }
    }
}