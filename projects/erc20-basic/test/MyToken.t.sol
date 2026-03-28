//SPDX-License-Identifier:MIT
pragma solidity >= 0.8.20;

import "forge-std/Test.sol";
import "../src/MyToken.sol";

contract MyTokenTest is Test {
    MyToken token;
    address alice = address(0x1);
    address bob = address(0x2);
    uint256 constant INITIAL_SUPPLY = 1000 * 10 ** 18;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed spender, uint256 value);

    function setUp() public {
        token = new MyToken(INITIAL_SUPPLY);
    }

    // --- 基础测试 ---

    function test_InitialSupply() public view {
        assertEq(token.totalSupply(), INITIAL_SUPPLY); 
        assertEq(token.balanceOf(address(this)), INITIAL_SUPPLY);
    }

    function test_Transfer() public {
        uint256 amount = 100 * 10 ** 18;
        
        // 期待触发 Transfer 事件
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(this), alice, amount);
        
        token.transfer(alice, amount);
        
        assertEq(token.balanceOf(alice), amount);
        assertEq(token.balanceOf(address(this)), INITIAL_SUPPLY - amount);
    }

    function test_Approve() public {
        uint256 amount = 50 * 10 ** 18;
        
        // 期待触发 Approval 事件
        vm.expectEmit(true, true, false, true);
        emit Approval(address(this), alice, amount);
        
        token.approve(alice, amount);
        assertEq(token.allowance(address(this), alice), amount);
    }

    function test_TransferFrom() public {
        uint256 amount = 100 * 10 ** 18;
        uint256 spendAmount = 50 * 10 ** 18;
        
        token.approve(alice, amount);
        
        
        vm.prank(alice);
        token.transferFrom(address(this), bob, spendAmount);
        
        assertEq(token.balanceOf(bob), spendAmount);
        // 关键点：检查授权额度是否正确减少
        assertEq(token.allowance(address(this), alice), amount - spendAmount);
    }

    // --- 失败路径测试 (Revert Testing) ---

    function test_FailTransferInsufficientBalance() public {
        vm.prank(alice);
        vm.expectRevert("insufficient balance");
        token.transfer(bob, 1);
    }

    function test_FailTransferFromInsufficientAllowance() public {
        uint256 amount = 100 * 10 ** 18;
        token.approve(alice, amount);
        
        vm.prank(alice);
        vm.expectRevert("insufficient allowance");
        token.transferFrom(address(this), bob, amount + 1);
    }

    function test_FailApproveToZeroAddress() public {
        vm.expectRevert("approve to zero address");
        token.approve(address(0), 100);
    }

    // --- 模糊测试 (Fuzz Testing) ---

    function testFuzz_Transfer(uint256 amount) public {
        // 限制 amount 不超过初始余额
        vm.assume(amount <= INITIAL_SUPPLY);
        
        token.transfer(alice, amount);
        assertEq(token.balanceOf(alice), amount);
        assertEq(token.balanceOf(address(this)), INITIAL_SUPPLY - amount);
    }
}