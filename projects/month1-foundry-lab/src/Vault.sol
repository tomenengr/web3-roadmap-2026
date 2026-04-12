// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title 基础金库 (大伯)
 */
contract BaseVault {
    uint256 public creationTime; // Slot 0
}

/**
 * @title 管理金库 (二伯)
 */
contract AdminVault {
    address public superAdmin;   // Slot 1 (20 字节)
    bool public isPaused;        // Slot 1 (1 字节)
}

/**
 * @title EVM 存储实验室 - 金库合约 (主角)
 * @dev 继承顺序是 BaseVault -> AdminVault -> Vault
 */
contract Vault is BaseVault, AdminVault {
    address public owner;      // 之前在 Slot 0，现在在哪？
    bool public isLocked;      
    
    uint128 public maxDeposit; 
    uint128 public minDeposit; 

    uint256 public totalBalance; 

    mapping(address => uint256) public balances; 

    uint256[] public ids; // 新增研究对象：Slot 6

    constructor() {
        owner = msg.sender;
        isLocked = true; 
        creationTime = block.timestamp;
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
        totalBalance += msg.value;
    }

    function withdraw(uint256 amount) external {
        if (balances[msg.sender] < amount) revert();
        balances[msg.sender] -= amount;
        totalBalance -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) revert();
    }
}
