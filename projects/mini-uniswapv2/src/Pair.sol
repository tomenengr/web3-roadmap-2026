//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./UniERC20.sol";
import "./ERC20.sol";
import "./Math.sol";
import "./IUniswapV2Callee.sol";
import "./IUniswapV2Factory.sol";

contract Pair is UniERC20 {

    address public token0;
    address public token1;
    address public factory;
    uint public constant MINIMUN_LIQUIDITY = 1000;

    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimestampLast;
    
    uint public price0CumulativeLast;
    uint public price1CumulativeLast;

    uint kLast;

    uint private unlock = 1;

    // 标准 Uniswap V2 事件
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);
    event MintFee(uint112 reserve0, uint112 reserve1);
    constructor() {
        factory = msg.sender;
    }

    modifier lock() {
        require(unlock == 1, "locked");
        unlock = 0;
        _;
        unlock = 1;
    }

    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, "not owner");
        token0 = _token0;
        token1 = _token1;
    }

    function getReserves() public view returns (uint112, uint112, uint32) {
        return (reserve0, reserve1, blockTimestampLast);
    }

    function _update(uint balance0, uint balance1) private {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, "overflow");
        
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed;
        unchecked {
            timeElapsed = blockTimestamp - blockTimestampLast;
        }

        if (timeElapsed > 0 && reserve0 != 0 && reserve1 != 0) {
            // 使用 UQ112x112 精度计算累积价格
            unchecked {
                price0CumulativeLast += uint(reserve1 << 112) / reserve0 * timeElapsed;
                price1CumulativeLast += uint(reserve0 << 112) / reserve1 * timeElapsed;
            }
        }

        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;

        emit Sync(reserve0, reserve1);
    }

    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IUniswapV2Factory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast;
        if(feeOn){
            if (_kLast != 0) {
            uint rootk = Math.sqrt(uint(reserve0) * reserve1);
            uint rootkLast = Math.sqrt(_kLast);
            if (rootk > rootkLast) {
                uint liquidity = totalSupply * (rootk - rootkLast) / (5 * rootk + rootkLast);
                if (liquidity > 0) _mint(feeTo, liquidity);
            }
            }
        }else if(kLast != 0) {
            kLast =0;
        }
        emit MintFee(_reserve0, _reserve1);
    }

    function mint(address to) external lock returns (uint liquidity) {
        uint balance0 = ERC20(token0).balanceOf(address(this));
        uint balance1 = ERC20(token1).balanceOf(address(this)); 
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        uint amount0 = balance0 - _reserve0;
        uint amount1 = balance1 - _reserve1;

        if (totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUN_LIQUIDITY;
            _mint(address(0), MINIMUN_LIQUIDITY);
        } else {
            liquidity = Math.min(amount0 * totalSupply / reserve0, amount1 * totalSupply / reserve1);
        }

        bool feeOn = _mintFee(_reserve0, _reserve1);
        require(liquidity > 0, "insufficient liquidity minted");
        _mint(to, liquidity);
        _update(balance0, balance1);
        if (feeOn) kLast =uint(_reserve0) * _reserve1;
        emit Mint(msg.sender, amount0, amount1);
    }

    function burn(address to, uint liquidity) external lock returns (uint amount0, uint amount1) {
        uint balance0 = ERC20(token0).balanceOf(address(this));
        uint balance1 = ERC20(token1).balanceOf(address(this));
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();

        amount0 = liquidity * balance0 / totalSupply;
        amount1 = liquidity * balance1 / totalSupply;
        require(amount0 > 0 && amount1 > 0, "insufficient liquidity burned");

        bool feeOn = _mintFee(_reserve0, _reserve1);
        _burn(msg.sender, liquidity);

        ERC20(token0).transfer(to, amount0);
        ERC20(token1).transfer(to, amount1);

        balance0 = ERC20(token0).balanceOf(address(this));
        balance1 = ERC20(token1).balanceOf(address(this));
        _update(balance0, balance1);

        if (feeOn) kLast =uint(_reserve0) * _reserve1;
        emit Burn(msg.sender, amount0, amount1, to);
    }

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
        require(amount0Out > 0 || amount1Out > 0, "insufficient output amount");
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        require(amount0Out < _reserve0 && amount1Out < _reserve1, "insufficient liquidity");
        require(to != token0 && to != token1, "invalid to");

        if (amount0Out > 0) ERC20(token0).transfer(to, amount0Out);
        if (amount1Out > 0) ERC20(token1).transfer(to, amount1Out);

        if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);

        uint balance0 = ERC20(token0).balanceOf(address(this));
        uint balance1 = ERC20(token1).balanceOf(address(this));

        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, "insufficient input amount");

        // K 值校验 (收 0.3% 手续费)
        {
            uint balance0Adjusted = balance0 * 1000 - (amount0In * 3);
            uint balance1Adjusted = balance1 * 1000 - (amount1In * 3);
            require(balance0Adjusted * balance1Adjusted >= uint(_reserve0) * _reserve1 * (1000**2), "K");
        }

        _update(balance0, balance1);

        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    function sync() external lock {
        uint balance0 = ERC20(token0).balanceOf(address(this));
        uint balance1 = ERC20(token1).balanceOf(address(this));
        emit Sync(uint112(balance0), uint112(balance1));
    }

    function skim(address _to) external lock {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        uint balance0 = ERC20(token0).balanceOf(address(this));
        uint balance1 = ERC20(token1).balanceOf(address(this));
        if (balance0 > _reserve0) ERC20(token0).transfer(_to, balance0 - _reserve0);
        if (balance1 > _reserve1) ERC20(token1).transfer(_to, balance1 - _reserve1);
        emit Sync(uint112(balance0), uint112(balance1));
    }

}
