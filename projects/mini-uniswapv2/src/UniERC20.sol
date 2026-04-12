//SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;

contract UniERC20 {
    uint public totalSupply = 0;
    string public name = "Uniswap";
    string public symbol = "UNI-LP";
    address public owner;
    uint public decimals = 18;

    // 1. 域名分隔符：防止别人把你在测试网签的名，拿到主网去重放攻击
    bytes32 public DOMAIN_SEPARATOR;

    // 2. 签名的结构类型哈希（EIP-712 规定的格式）
    // 对应结构：Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    // 3. 记录每个用户的 nonce（防重放攻击：同一个签名只能用一次）
    mapping(address => uint) public nonces;

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );

    }

    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) public returns (bool) {
        require(balanceOf[msg.sender] >= value, "not enough");
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf[from] >= value, "not enough");
        require(allowance[from][msg.sender] >= value, "not approved");
        allowance[from][msg.sender] -= value;
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
        return true;
    }

    function _mint(address account, uint value) internal { 
        balanceOf[account] += value;
        totalSupply += value;
        emit Transfer(address(0), account, value);
    }

    function _burn(address account, uint value) internal {
        require(balanceOf[account] >= value, "not enough");
        balanceOf[account] -= value;
        totalSupply -= value;
        emit Transfer(account, address(0), value);
    }

    function getTotalSupply() public view returns (uint) {
        return totalSupply;
    }

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(block.timestamp <= deadline, "permit expired");

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );

        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "invalid signature");

        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
}
