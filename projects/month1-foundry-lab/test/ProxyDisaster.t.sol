// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ProxyDisaster.sol";
import "../src/Vault.sol";

contract ProxyDisasterTest is Test {
    SimpleProxy public proxy;
    Vault public v1;
    VaultV2_Broken public v2Broken;

    address public admin = address(0xAAAA);

    function setUp() public {
        v1 = new Vault();
        v2Broken = new VaultV2_Broken();
        // 初始化代理，指向 V1
        proxy = new SimpleProxy(address(v1));
    }

    /**
     * @notice 灾难 1：代理合约与逻辑合约的存储碰撞 (Storage Collision)
     * 因为代理的 Slot 0 是 implementation，逻辑合约的 Slot 0 是 creationTime
     */
    function test_ProxyImplementationCorruption() public {
        console.log("Initial Proxy Imp Address:", address(proxy.implementation()));
        
        // 我们通过代理调用 Vault 的逻辑（比如设置 creationTime 的逻辑）
        // Vault 的构造函数在部署时已经跑过了，但我们可以通过 delegatecall 调用它的方法
        // 注意：Vault 构造函数里的赋值在 delegatecall 时是不生效的，除非我们在 logic 里加 initialize
        
        // 既然 Vault 逻辑里没法改 Slot 0，我们换个思路。
        // Vault 继承了 BaseVault，如果我们往 BaseVault 强行塞个值：
        // (实际上我们可以直接修改 Vault.sol 来增加一个修改 Slot 0 的函数)
        
        // 演示：逻辑合约认为自己在改 creationTime，实际上改了代理的 implementation
        // 我们模拟这种行为：
        vm.prank(address(proxy));
        // 我们需要通过汇编或伪造调用来触发逻辑合约对 Slot 0 的修改
        // 为了演示方便，我们假设 Vault 有个 setter
        
        console.log("--- BEFORE COLLISION ---");
        console.log("Implementation Slot 0 value (address):", address(proxy.implementation()));

        // 手动在代理合约的 Slot 0 处存入一个大数字（模拟逻辑合约修改了 Slot 0）
        uint256 bigData = 0xDEADBEEF;
        vm.store(address(proxy), bytes32(0), bytes32(bigData));

        console.log("--- AFTER COLLISION ---");
        console.log("Implementation Slot 0 value now (address):", address(proxy.implementation()));
        
        // 结局：代理合约现在指向了 0xDEADBEEF，已经报废了
        assertEq(uint160(address(proxy.implementation())), bigData);
    }

    /**
     * @notice 灾难 2：升级时的存储槽位错位 (Storage Misalignment)
     * V1: Slot 0 = creationTime, Slot 1 = superAdmin, isPaused
     * V2 (Broken): Slot 0 = superAdmin, isPaused, Slot 1 = creationTime
     */
    function test_UpgradeDisaster() public {
        // 1. 在 V1 阶段设置一些数据
        // 手动在代理存储中模拟 V1 的布局
        uint256 time = 123456789;
        address currentSuperAdmin = address(0xBEEF);
        
        vm.store(address(proxy), bytes32(uint256(0)), bytes32(time)); // creationTime @ Slot 0
        vm.store(address(proxy), bytes32(uint256(1)), bytes32(uint256(uint160(currentSuperAdmin)))); // superAdmin @ Slot 1
        
        console.log("V1 State (in Proxy storage):");
        console.log("- creationTime:", time);
        console.log("- superAdmin:", currentSuperAdmin);

        // 2. 模拟“升级”代理到 V2_Broken
        // 注意：这里我们得跳过灾难 1，直接假设 implementation 修改成功
        // 我们直接强行修改代理的存储来更换实现合约（虽然在现实中这通常是通过 upgradeTo 函数完成的）
        // 但这里我们简单起见，直接观察存储布局的变化
        
        // 如果我们现在用 V2_Broken 的视角去读：
        // 它会认为 Slot 0 是 superAdmin
        
        // 我们模拟这个读取：
        bytes32 slot0Value = vm.load(address(proxy), bytes32(uint256(0)));
        address misalignedAdmin = address(uint160(uint256(slot0Value)));
        
        console.log("--- AFTER UPGRADE TO BROKEN V2 ---");
        console.log("V2 thinks Slot 0 is superAdmin. Value read:", misalignedAdmin);
        
        // 结局：原本的时间戳 123456789 被当成了超级管理员地址！
        assertEq(uint160(misalignedAdmin), time);
    }
}
