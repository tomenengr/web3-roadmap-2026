// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Vault.sol";

/**
 * @title 一个极简的代理合约
 */
contract SimpleProxy {
    // Slot 0: 逻辑合约地址 (注意：这在实际开发中通常放在 EIP-1967 指定的远端槽位，
    // 但为了演示灾难，我们故意把它放在 Slot 0，看看会发生什么)
    address public implementation;

    constructor(address _imp) {
        implementation = _imp;
    }

    fallback() external payable {
        address _imp = implementation;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _imp, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}

/**
 * @title 翻车版 Vault V2
 * @notice 灾难点：改变了继承顺序或在最前面增加了变量
 */
contract VaultV2_Broken is AdminVault, BaseVault { // 故意颠倒了顺序！
    // 原始顺序是 BaseVault (creationTime), AdminVault (superAdmin, isPaused)
    // 现在的顺序是 AdminVault (superAdmin, isPaused), BaseVault (creationTime)
    
    // Slot 0 现在变成了 superAdmin
    // Slot 1 现在变成了 creationTime
    
    address public owner; 
    bool public isLocked;
    // ... 后面也全乱了
    
    function initializeV2() external {
        // 模拟升级后的操作
    }
}
