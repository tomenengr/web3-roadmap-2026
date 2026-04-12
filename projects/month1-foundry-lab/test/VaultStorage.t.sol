// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Vault.sol";

contract VaultStorageTest is Test {
    Vault public vault;
    address public owner = address(0x1234567890123456789012345678901234567890);

    function setUp() public {
        vm.prank(owner);
        vault = new Vault();
    }

    /**
     * @notice 验证 Mapping 的存储计算
     * 公式: keccak256(key, p)
     */
    function test_MappingStorage() public {
        uint256 depositAmount = 1.5 ether;
        vm.deal(owner, depositAmount);
        
        vm.prank(owner);
        vault.deposit{value: depositAmount}();

        // 1. Mapping 声明的主位是 Slot 5
        uint256 p = 5; 

        // 2. 计算存储槽：keccak256(abi.encode(owner, p))
        bytes32 calculatedSlot = keccak256(abi.encode(owner, p));

        // 3. 用 vm.load 直接从合约里抠出这个槽的数据
        bytes32 storedValue = vm.load(address(vault), calculatedSlot);

        console.log("--- Mapping Storage Hack ---");
        console.log("Mapping Base Slot (p):", p);
        console.logBytes32(calculatedSlot);
        console.log("Value in Slot:", uint256(storedValue) / 1e18, "ether");

        assertEq(uint256(storedValue), depositAmount, "Mapping data mismatch!");
    }

    /**
     * @notice 验证 动态数组 的存储计算
     * 公式: 主位存长度，数据在 keccak256(p) + index
     */
    function test_ArrayStorage() public {
        // 1. 数组声明的主位是 Slot 6
        uint256 p = 6;

        // 2. 模拟往数组里塞点数据 (通过伪造存储或调用，这里咱们直接模拟)
        // ids.push(888); ids.push(999);
        vm.prank(address(vault)); // 假设合约自己调用（或者我们直接用 vm.store 暴力塞）
        // 为了方便演示，我们直接往合约里塞两个数
        uint256[] memory data = new uint256[](2);
        data[0] = 888;
        data[1] = 999;
        
        // 实际上我们可以直接写个函数 push，或者暴力修改：
        // 修改主位存长度 = 2
        vm.store(address(vault), bytes32(uint256(p)), bytes32(uint256(2)));
        
        // 计算数据起始位置
        bytes32 baseSlot = keccak256(abi.encode(p));
        // 修改数据槽
        vm.store(address(vault), baseSlot, bytes32(uint256(888))); // index 0
        vm.store(address(vault), bytes32(uint256(baseSlot) + 1), bytes32(uint256(999))); // index 1

        // 3. 验证长度
        bytes32 lengthInSlot = vm.load(address(vault), bytes32(uint256(p)));
        console.log("--- Array Storage Hack ---");
        console.log("Array Base Slot (p) [Stores Length]:", p);
        console.log("Length from Storage:", uint256(lengthInSlot));

        // 4. 验证数据位置
        bytes32 slot0 = keccak256(abi.encode(p));
        bytes32 slot1 = bytes32(uint256(slot0) + 1);

        uint256 val0 = uint256(vm.load(address(vault), slot0));
        uint256 val1 = uint256(vm.load(address(vault), slot1));

        console.log("Data Slot 0 (keccak256(p)):");
        console.logBytes32(slot0);
        console.log("Value at Index 0:", val0);

        console.log("Data Slot 1 (keccak256(p) + 1):");
        console.logBytes32(slot1);
        console.log("Value at Index 1:", val1);

        assertEq(val0, 888);
        assertEq(val1, 999);
    }
}
