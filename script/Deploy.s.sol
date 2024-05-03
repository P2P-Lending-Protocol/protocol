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

    // address daiToken = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    // address USDCAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    // // address WETHAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    //SEPOLIA TESTNET ADDRESSES
    // address daiToken = 0x3e622317f8C93f7328350cF0B56d9eD4C620C5d6;
    address linkToken = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
    // address USDCToken = 0xf08A50178dfcDe18524640EA6618a1f965821715;

    // address daiPriceFeed = 0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9;
    address linkPriceFeed = 0xc59E3633BAAC79493d908e63626716e204A45EdF;
    // address usdcPriceFeed = 0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E;
    // address WETHPriceFeed = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419; //ETH-USD

    function setUp() public {
        // _tokenAddresses.push(daiToken);
        _tokenAddresses.push(linkToken);
        // _tokenAddresses.push(USDCToken);
        // tokens.push(USDCAddress);
        // _tokenAddresses.push(WETHAddress);

        // _priceFeedAddresses.push(daiPriceFeed);
        _priceFeedAddresses.push(linkPriceFeed);
        // _priceFeedAddresses.push(usdcPriceFeed);
        // _priceFeedAddresses.push(WETHPriceFeed);
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
