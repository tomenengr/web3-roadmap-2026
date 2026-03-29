// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.20;

import "forge-std/Script.sol";
import "../src/MyToken.sol";

contract DeployMyToken is Script {
    function run() external returns (MyToken) {
        // 1. 设置初始供应量 (1000 MTK，带 18 位精度)
        uint256 initialSupply = 1000 * 10 ** 18;

        // 2. 开始广播交易
        // 这一行之后的调用都会被记录并准备发送到链上
        vm.startBroadcast();

        // 3. 部署合约
        MyToken token = new MyToken(initialSupply);

        // 4. 结束广播
        vm.stopBroadcast();

        return token;
    }
}