// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradable/proxy/utils/Initializable.sol";

contract Protocol is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    // TODO: Add your state variables here
    // TODO: Convert ERC20 to ERC20Upgradeable
    function initialize() public initializer {
        __Ownable_init();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
