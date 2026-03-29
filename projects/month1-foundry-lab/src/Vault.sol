// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EVM 存储实验室 - 金库合约
 * @dev 这是一个专门用来练习 Storage Slot 布局的合约。
 * 目标：观察不同大小的变量是如何在 32 字节的槽位中被打包(Pack)或分隔的。
 */
contract Vault {
    // --- Slot 0 ---
    address public owner;      // 20 字节
    bool public isLocked;      // 1 字节
    // 合计 21 字节，还剩下 11 字节。
    
    // --- Slot 1 (如果放在这里会溢出 Slot 0) ---
    uint128 public maxDeposit; // 16 字节 (放在 Slot 1)
    uint128 public minDeposit; // 16 字节 (正好填满 Slot 1)

    // --- Slot 2 ---
    uint256 public totalBalance; // 32 字节 (独占 Slot 2)

    // --- 映射与复杂类型 ---
    mapping(address => uint256) public balances; // Slot 3 (只存占位符，数据存他在的地方)

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    error Unauthorized();
    error TransferFailed();

    constructor() {
        owner = msg.sender;
        isLocked = true; // 为了实验观察，我们把它设为 true
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
        totalBalance += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        if (balances[msg.sender] < amount) revert TransferFailed();
        
        balances[msg.sender] -= amount;
        totalBalance -= amount;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) revert TransferFailed();
        
        emit Withdraw(msg.sender, amount);
    }
}
