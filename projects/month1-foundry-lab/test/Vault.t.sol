// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Vault.sol";

contract VaultTest is Test {
    Vault public vault;
    address public owner = address(0x1234567890123456789012345678901234567890);

    function setUp() public {
        vm.prank(owner);
        vault = new Vault();
    }

    /**
     * @dev 实验 4：手动“抠出”打包在 Slot 0 里的 bool 变量
     */
    function test_ExtractIsLocked() public {
        // 1. 读取 Slot 0
        bytes32 slot0 = vm.load(address(vault), bytes32(uint256(0)));

        // 2. 位运算“剥壳”过程：
        // (1) 转为 uint256：[空][isLocked][owner]
        uint256 rawValue = uint256(slot0);

        // (2) 向右移 160 位（把 20 字节的 owner 挤掉）：[空][isLocked]
        uint256 shiftedValue = rawValue >> 160;

        // (3) 逻辑判断转为 bool：如果 uint8(shiftedValue) 不为 0，即为 true
        bool extractedLocked = (uint8(shiftedValue) != 0);

        // 3. 验证：我们在构造函数里设为 true，所以这里必须是 true！
        console.log("Extracted isLocked value:");
        console.log(extractedLocked);

        assertEq(extractedLocked, true, "Extracted value should be true");
        console.log("Success! Manually extracted isLocked from Slot 0.");
    }

    // ... 保留之后的测试 ...
    function test_StorageLayout() public {
        bytes32 slot0 = vm.load(address(vault), bytes32(uint256(0)));
        address storedOwner = address(uint160(uint256(slot0)));
        assertEq(storedOwner, owner);
    }

    function test_MappingStorage() public {
        uint256 depositAmount = 1 ether;
        vm.deal(owner, depositAmount);
        vm.prank(owner);
        vault.deposit{value: depositAmount}();

        uint256 p = 3; 
        bytes32 calculatedSlot = keccak256(abi.encode(owner, p));
        bytes32 storedData = vm.load(address(vault), calculatedSlot);
        assertEq(uint256(storedData), depositAmount);
    }
}

