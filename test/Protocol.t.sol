// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {PeerToken} from "../src/PeerToken.sol";
import {Protocol} from "../src/Protocol.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ProtocolTest is Test {
    PeerToken private peerToken;
    Protocol public protocol;
    address [] tokens;
    address [] priceFeed;
 
    address owner = address(0xa);
    address B = address(0xb);
    address diaToken = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address USDCAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
   address WETHAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;


    function setUp() public {
        owner = mkaddr("owner");
        switchSigner(owner);
        B = mkaddr("receiver b");
        peerToken = new PeerToken();
        protocol = new Protocol();

        tokens.push(diaToken);
        tokens.push(USDCAddress);
        tokens.push(WETHAddress);

        priceFeed.push(diaToken);
        priceFeed.push(WETHAddress);
        priceFeed.push(USDCAddress);
        protocol.initialize(owner,tokens, priceFeed, address(peerToken));

    }

    function testDepositQualateral() external {
            // protocol.initialize(owner,tokens, priceFeed, address(peerToken));
            switchSigner(diaToken);
            // console.log("balance is ::: ",IERC20(diaToken).balanceOf(address(0)));
            IERC20(diaToken).transfer(owner, 10000);

            switchSigner(owner);
            IERC20(diaToken).approve(address(protocol), 1000);
            protocol.depositCollateral(diaToken, 1000);
            // address [] memory collateralAddr = protocol.getAllCollateralToken();
            // assertEq(collateralAddr.length, 1);
    }









function mkaddr(string memory name) public returns (address) {
        address addr = address(
            uint160(uint256(keccak256(abi.encodePacked(name))))
        );
        vm.label(addr, name);
        return addr;
    }

function switchSigner(address _newSigner) public {
        address foundrySigner = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;
        if (msg.sender == foundrySigner) {
            vm.startPrank(_newSigner);
        } else {
            vm.stopPrank();
            vm.startPrank(_newSigner);
        }
    }

}