// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WETH is ERC20 {
    constructor() ERC20("Wrapped Ether", "WETH") {}

    function deposit() public payable {
        // 检查发送者是否发送了 ETH
        _mint(msg.sender, msg.value);
        
    }

    function withdraw(uint256 amount) public {
        // 检查 WETH 余额
        require(balanceOf(msg.sender) >= amount, "Insufficient WETH balance.");
        // 销毁发送者 WETH 
        _burn(msg.sender, amount);
        // 发送给发送者等量 ETH
        payable(msg.sender).transfer(amount);
    }
}