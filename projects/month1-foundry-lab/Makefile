-include .env

.PHONY: all test build deploy balance name

build :; forge build

test :; forge test

# 部署合约并广播
deploy :
	@forge script script/DeployMyToken.s.sol --rpc-url $(RPC_URL) --broadcast --private-key $(PRIVATE_KEY)

# 查名字 (读操作)
name :
	@cast call $(TOKEN_ADDR) "name()(string)" --rpc-url $(RPC_URL)

# 查余额 (读操作)
# 用法: make balance ADDR=0xf39...
balance :
	@cast call $(TOKEN_ADDR) "balanceOf(address)(uint256)" $(ADDR) --rpc-url $(RPC_URL)

# 给 Alice 转账 100 MTK (写操作)
transfer-alice :
	@cast send $(TOKEN_ADDR) "transfer(address,uint256)(bool)" $(ALICE) 100000000000000000000 --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY)
