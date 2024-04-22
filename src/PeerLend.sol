// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import "@openzeppelin/contracts-upgradeable@5.0.2/token/ERC20/ERC20Upgradeable.sol";
// import "@openzeppelin/contracts-upgradeable@5.0.2/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable@5.0.2/access/OwnableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable@5.0.2/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts-upgradeable@5.0.2/proxy/utils/UUPSUpgradeable.sol";

import "./Governance.sol";
import "./PeerToken.sol";

contract PeerLend is PeerToken, Governance {
    // TODO: Add your state variables here
    // TODO: Convert ERC20 to ERC20Upgradeable
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) public initializer {
        __ERC20_init("MyToken", "MTK");
        __ERC20Burnable_init();
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }
}
