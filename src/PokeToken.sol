// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PokeToken is ERC20, Ownable {
    uint256 public constant MAX_AIRDROP_ADDRESSES = 10;
    uint256 public constant INITIAL_SUPPLY = 1e18 * 1e18;

   event BatchAirdrop(address indexed owner, address[] recipients, uint256[] amounts);

    constructor() ERC20("Pokes", "POKE") Ownable(msg.sender) {
        _mint(address(this), INITIAL_SUPPLY);
    }

    function batchAirdrop(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        require(recipients.length == amounts.length, "PokeToken: recipients and amounts length mismatch");
        require(recipients.length > 0 && recipients.length <= MAX_AIRDROP_ADDRESSES, "PokeToken: invalid number of recipients");
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        require(balanceOf(address(this)) >= totalAmount, "PokeToken: insufficient contract balance");
        for (uint256 i = 0; i < recipients.length; i++) {
            _transfer(address(this), recipients[i], amounts[i]);
        }
        emit BatchAirdrop(msg.sender, recipients, amounts);
    }
} 