// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {Protocol} from "../src/Protocol.sol";

// deployment script
// forge script ./script/Deploy.s.sol --broadcast -vvvv --account <wallet-account> --sender <sender-address>

contract UpgradeScript is Script {
    Protocol internal protocol;
    address proxyAddr = 0xAB6015514c40F5B0bb583f28c0819cA79e3B9415;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        Upgrades.upgradeProxy(
            proxyAddr,
            "Protocol.sol:Protocol",
            "",
            msg.sender
        );

        vm.stopBroadcast();
    }
}
