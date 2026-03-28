// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MyToken.sol";

contract MyTokenTest is Test {
    MyToken public token;
    address public owner = address(1);
    address public user1 = address(2);
    address public user2 = address(3);
    uint256 public initialSupply = 1000 ether;

    function setUp() public {
        vm.prank(owner);
        token = new MyToken(initialSupply);
    }

    function test_InitialSupply() public {
        assertEq(token.totalSupply(), initialSupply);
        assertEq(token.balanceOf(owner), initialSupply);
    }

    function test_Transfer() public {
        uint256 amount = 100 ether;
        vm.prank(owner);
        token.transfer(user1, amount);
        assertEq(token.balanceOf(user1), amount);
        assertEq(token.balanceOf(owner), initialSupply - amount);
    }

    function test_FailTransferInsufficientBalance() public {
        uint256 amount = 2000 ether;
        vm.prank(user1);
        // 匹配自定义错误 ERC20InsufficientBalance
        vm.expectRevert(
            abi.encodeWithSelector(MyToken.ERC20InsufficientBalance.selector, user1, 0, amount)
        );
        token.transfer(user2, amount);
    }

    function test_Approve() public {
        uint256 amount = 50 ether;
        vm.prank(owner);
        token.approve(user1, amount);
        assertEq(token.allowance(owner, user1), amount);
    }

    function test_TransferFrom() public {
        uint256 amount = 50 ether;
        vm.prank(owner);
        token.approve(user1, amount);

        vm.prank(user1);
        token.transferFrom(owner, user2, amount);

        assertEq(token.balanceOf(user2), amount);
        assertEq(token.allowance(owner, user1), 0);
    }

    // --- 新增测试：Mint ---

    function test_Mint() public {
        uint256 amount = 500 ether;
        vm.prank(owner);
        token.mint(user1, amount);
        assertEq(token.balanceOf(user1), amount);
        assertEq(token.totalSupply(), initialSupply + amount);
    }

    function test_FailMintUnauthorized() public {
        uint256 amount = 500 ether;
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(MyToken.Unauthorized.selector, user1));
        token.mint(user1, amount);
    }

    // --- 新增测试：Burn ---

    function test_Burn() public {
        uint256 amount = 100 ether;
        vm.prank(owner);
        token.burn(amount);
        assertEq(token.balanceOf(owner), initialSupply - amount);
        assertEq(token.totalSupply(), initialSupply - amount);
    }

    // --- Fuzz Test ---
    function testFuzz_Transfer(uint256 amount) public {
        // 限制金额在有效范围内
        vm.assume(amount <= initialSupply);
        vm.prank(owner);
        token.transfer(user1, amount);
        assertEq(token.balanceOf(user1), amount);
    }
}
