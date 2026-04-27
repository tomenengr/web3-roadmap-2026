# 🛠️ Foundry 极简测试通关指南

> 这里的作弊码和断言是我们在开发 `mini-uniswapv2` 时最亲密的战友。

## 1. 作弊码 (Cheatcodes) - `vm` 对象
作弊码允许我们在测试中通过 `vm` 对象改变区块链的状态。

### 🎭 身份切换
*   `vm.prank(address)`：设置下一笔交易的 `msg.sender`。
*   `vm.startPrank(address)`：设置之后所有交易的 `msg.sender`，直到调用 `vm.stopPrank()`。
*   **用途**：模拟用户、管理员或黑客的操作。

### 💰 资产操控
*   `vm.deal(address, uint256)`：设置某个地址的 ETH 余额。
*   `deal(address(token), address(user), uint256)`：(需导入 `StdCheats`) 直接设置用户的 ERC20 余额。

### ⏳ 时空穿梭
*   `vm.warp(uint256)`：修改 `block.timestamp`（秒）。
*   `vm.roll(uint256)`：修改 `block.number`。
*   **用途**：测试 `deadline` 限制或基于区块的流动性挖矿。

### 🚫 报错预期
*   `vm.expectRevert(bytes memory message)`：预期下一笔交易必须失败，且报错信息匹配。
*   **用途**：测试 `require` 检查是否生效。

---

## 2. 断言 (Assertions) - `StdAssertions`
断言用于验证合约状态是否符合预期。

*   `assertEq(actual, expected, "error message")`：判断相等。
*   `assertTrue(condition)`：判断为真。
*   `assertGt(a, b)`：判断 `a > b`。
*   `assertApproxEqAbs(a, b, delta)`：判断 `a` 和 `b` 的差值不超过 `delta`。
    *   **提示**：在 DeFi 中，由于除法精度问题，经常会出现差 1 wei 的情况，这时候用这个断言非常稳！

---

## 3. 常用命令 (Forge CLI)
在 `projects/mini-uniswapv2/` 目录下运行：

```bash
# 基本运行
forge test

# 显示日志 (vv = verbose, vvv = trace, vvvv = full trace)
forge test -vv

# 运行特定测试
forge test --match-test testSwap -vvv

# 过滤文件
forge test --match-path test/Pair.t.sol

# 监听模式（边写边测，效率极高）
forge test --watch
```

---

## 💡 实战小贴士
1.  **日志调试**：在合约或测试里用 `console.log(uint256)`，配合 `-vv` 命令查看变量。
2.  **错误堆栈**：如果测试莫名挂了，用 `-vvv` 看 Trace，它会用红色标出是哪一行代码 Revert 了。
3.  **地址标签**：在 `setUp` 里用 `vm.label(alice, "Alice")`，Trace 里的 `0x123...` 就会变成 `Alice`，极其好读！
