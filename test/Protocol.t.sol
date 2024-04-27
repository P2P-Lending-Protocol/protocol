// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {PeerToken} from "../src/PeerToken.sol";
import {Protocol} from "../src/Protocol.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IProtocolTest} from "./IProtocolTest.sol";
import "../src/Libraries/Errors.sol";

contract ProtocolTest is Test, IProtocolTest{
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

    function testDepositQualateral() public {
            // protocol.initialize(owner,tokens, priceFeed, address(peerToken));
            switchSigner(WETHAddress);
            // console.log("balance is ::: ",IERC20(diaToken).balanceOf(address(0)));
            IERC20(WETHAddress).transfer(owner, 10000);

            switchSigner(owner);
            IERC20(WETHAddress).approve(address(protocol), 10000);
            protocol.depositCollateral(WETHAddress, 10000);
            uint256  _amountQualaterized = protocol.gets_addressToCollateralDeposited(owner, WETHAddress);
            assertEq(_amountQualaterized, 10000);
    }

    function testCreateLendingRequest() public {
            testDepositQualateral();
            protocol.createLendingRequest(WETHAddress, 5000,5,2 days);
             uint _lenght = protocol.getAllRequest().length;
            assertEq(_lenght, 1);
    }

   function testMultipleLendingRequests() public {
    testDepositQualateral();

    // First request: 50% of the collateral
    protocol.createLendingRequest(WETHAddress, 5000, 5, 2 days);

    // Second request: 10% of the collateral
    protocol.createLendingRequest(WETHAddress, 1000, 5, 3 days);

    // Total borrowed so far: 60% which is below 85%
    uint _length = protocol.getAllRequest().length;
    assertEq(_length, 2);

    // This request would bring the total to 100%, which should fail since it exceeds the 85% limit
    vm.expectRevert(abi.encodeWithSelector(INSUFFICIENT_COLLATERAL.selector));
    protocol.createLendingRequest(WETHAddress, 5000, 5, 4 days);
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