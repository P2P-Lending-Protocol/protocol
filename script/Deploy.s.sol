// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {PeerToken} from "../src/PeerToken.sol";
import {Protocol} from "../src/Protocol.sol";
import {Governance} from "../src/Governance.sol";
// import {IProtocolTest} from "../IProtocolTest.sol";
import "../src/Libraries/Errors.sol";

// deployment script
// forge script ./script/Deploy.s.sol --broadcast -vvvv --account <wallet-account> --sender <sender-address>

contract DeployScript is Script {
    PeerToken peerToken;
    Protocol protocol;
    Governance governance;

    ERC1967Proxy proxy;

    address[] _tokenAddresses;
    address[] _priceFeedAddresses;

    address daiToken = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    // address USDCAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address WETHAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address daiPriceFeed = 0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9;
    address WETHPriceFeed = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419; //ETH-USD

    function setUp() public {
        _tokenAddresses.push(daiToken);
        // tokens.push(USDCAddress);
        _tokenAddresses.push(WETHAddress);

        _priceFeedAddresses.push(daiPriceFeed);
        _priceFeedAddresses.push(WETHPriceFeed);
    }

    function run() public {
        vm.startBroadcast();
        peerToken = new PeerToken(msg.sender);

        governance = new Governance(address(peerToken));

        Protocol implementation = new Protocol();
        // Deploy the proxy and initialize the contract through the proxy
        proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeCall(
                implementation.initialize,
                (
                    msg.sender,
                    _tokenAddresses,
                    _priceFeedAddresses,
                    address(peerToken)
                )
            )
        );
        // Attach the MyToken interface to the deployed proxy
        console.log("$PEER address", address(peerToken));
        console.log("Governance address", address(governance));
        console.log("Proxy Address", address(proxy));
        console.log("Protocol address", address(implementation));

        vm.stopBroadcast();
    }
}
