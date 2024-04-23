// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @title The Proxy Contract for the protocol
/// @author Benjamin Faruna, Favour Aniogor
/// @notice This uses the EIP1822 UUPS standard from the opwnzeppelin library
contract Protocol is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    /// @dev maps collateral token to their price feed
    mapping(address token => address priceFeed) private s_priceFeeds;
    /// @dev maps user to the value of balance he has collaterised
    mapping(bytes32 => mapping(address token => uint256 balance))
        private s_addressToCollateralDeposited;
    /// @dev Collection of all colleteral Adresses
    address[] private s_collateralToken;
    /// @dev Our utility Token $PEER TODO: import the PEER Token Contract
    PeerToken private immutable i_PEER;

    //Structs For OFFers
    //Struct For Request

    /// @dev Acts as our contructor
    /// @param _initialOwner a parameter just like in doxygen (must be followed by parameter name)
    function initialize(
        address _initialOwner,
        address[] memory _tokens,
        address[] memory _priceFeeds,
        address _peerAddress
    ) public initializer {
        __Ownable_init(_initialOwner);
        if (_tokens.length != _priceFeeds.length) {
            // TODO: Revert with an Error
        }
        for (uint8 i = 0; i < _tokens.length; i++) {
            s_priceFeeds[_tokens[i]] = _priceFeeds[i];
            s_collateralToken.push(_tokens[i]);
        }
        i_PEER = PeerToken(_peerAddress);
    }

    /// @dev Assist with upgradable proxy
    /// @param address a parameter just like in doxygen (must be followed by parameter name)
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
interface Protocol {
    function depositCollateral();
    function redeemCollateral();
    function createRequest();
    function serviceRequest();
    function liquidateUser();
}
