// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MyToken {
    // --- 状态变量 ---
    string public name = "MyToken";
    string public symbol = "MTK";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    address public owner;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // --- 事件 ---
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // --- 自定义错误 (Gas 优化) ---
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
    error ERC20InvalidSender(address sender);
    error ERC20InvalidReceiver(address receiver);
    error Unauthorized(address account);

    // --- 修饰符 ---
    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized(msg.sender);
        _;
    }

    constructor(uint256 _initialSupply) {
        owner = msg.sender;
        _mint(msg.sender, _initialSupply);
    }

    // --- 外部函数 ---

    function transfer(address _to, uint256 _value) external returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        _approve(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        uint256 currentAllowance = allowance[_from][msg.sender];
        if (currentAllowance < _value) {
            revert ERC20InsufficientAllowance(msg.sender, currentAllowance, _value);
        }
        
        _approve(_from, msg.sender, currentAllowance - _value);
        _transfer(_from, _to, _value);
        return true;
    }

    // --- 扩展功能：Mint & Burn ---

    /**
     * @dev 只有 Owner 可以增发代币
     */
    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }

    /**
     * @dev 任何人都可以燃烧自己的代币
     */
    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }

    // --- 内部逻辑 (Internal Functions) ---

    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) revert ERC20InvalidSender(address(0));
        if (to == address(0)) revert ERC20InvalidReceiver(address(0));

        uint256 fromBalance = balanceOf[from];
        if (fromBalance < value) {
            revert ERC20InsufficientBalance(from, fromBalance, value);
        }

        unchecked {
            // 在检查过余额后，减法可以用 unchecked 稍微省点 Gas
            balanceOf[from] = fromBalance - value;
            balanceOf[to] += value;
        }

        emit Transfer(from, to, value);
    }

    function _approve(address ownerAddr, address spender, uint256 value) internal {
        if (ownerAddr == address(0)) revert ERC20InvalidSender(address(0));
        if (spender == address(0)) revert ERC20InvalidReceiver(address(0));

        allowance[ownerAddr][spender] = value;
        emit Approval(ownerAddr, spender, value);
    }

    function _mint(address account, uint256 value) internal {
        if (account == address(0)) revert ERC20InvalidReceiver(address(0));

        totalSupply += value;
        unchecked {
            balanceOf[account] += value;
        }
        emit Transfer(address(0), account, value);
    }

    function _burn(address account, uint256 value) internal {
        if (account == address(0)) revert ERC20InvalidSender(address(0));

        uint256 accountBalance = balanceOf[account];
        if (accountBalance < value) {
            revert ERC20InsufficientBalance(account, accountBalance, value);
        }

        unchecked {
            balanceOf[account] = accountBalance - value;
            totalSupply -= value;
        }
        emit Transfer(account, address(0), value);
    }
}
