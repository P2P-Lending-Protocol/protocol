// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Protocol is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    // TODO: Add your state variables here
    // TODO: Convert ERC20 to ERC20Upgradeable
    function initialize(address _initialOwner) public initializer {
        __Ownable_init(_initialOwner);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
