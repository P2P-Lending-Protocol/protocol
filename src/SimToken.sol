// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SimToken
 * @dev ERC20 token implementation.
 */

contract SimToken is ERC20, ERC20Burnable, Ownable {
    /**
     * @dev Constructor function
     * @param initialOwner The address that will initially own all tokens.
     */

    constructor(address initialOwner) ERC20("SIM", "STK") Ownable(initialOwner) {}
    
     /**
     * @dev Mints new tokens and assigns them to the specified address.
     * @param to The address to which the minted tokens will be assigned.
     * @param amount The amount of tokens to mint.
     * @notice Only the owner of the contract can call this function.
     */

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
