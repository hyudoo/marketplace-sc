// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Floppy is ERC20, Ownable {
    uint256 private cap = 50_000_000_000 * 10 ** uint256(18);

    constructor() ERC20("Floppy", "FLP") Ownable(msg.sender) {}

    function mint(address to, uint256 amount) public onlyOwner {
        require(ERC20.totalSupply() + amount <= cap, "Floppy: cap exceeded");
        _mint(to, amount);
    }
}
