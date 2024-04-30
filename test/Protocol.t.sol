// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {PeerToken} from "../src/PeerToken.sol";
import {Protocol} from "../src/Protocol.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IProtocolTest} from "./IProtocolTest.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "../src/Libraries/Errors.sol";


contract ProtocolTest is Test, IProtocolTest{
    PeerToken private peerToken;
    Protocol public protocol;
    address [] tokens;
    address [] priceFeed;

 
    address owner = address(0xa);
    address B = address(0xb);
    address diaToken = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    // address USDCAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
   address WETHAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

   address WETH_USD = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
   address DAI_USD = 0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9;


    function setUp() public {
        owner = mkaddr("owner");
        switchSigner(owner);
        B = mkaddr("receiver b");
        peerToken = new PeerToken(owner);
        protocol = new Protocol();

        // tokens.push(USDCAddress);
        tokens.push(diaToken);
        tokens.push(WETHAddress);

        priceFeed.push(DAI_USD);
        priceFeed.push(WETH_USD);
        // priceFeed.push(USDCAddre
        protocol.initialize(owner,tokens, priceFeed, address(peerToken));
        IERC20(WETHAddress).approve(address(protocol), type(uint).max);
        IERC20(diaToken).approve(address(protocol), type(uint).max);


    }


    function testDepositTCollateral() public {
            // protocol.initialize(owner,tokens, priceFeed, address(peerToken));
            switchSigner(WETHAddress);
            // console.log("balance is ::: ",IERC20(diaToken).balanceOf(address(0)));
            IERC20(WETHAddress).transfer(owner, 1 ether );

            switchSigner(owner);
            protocol.depositCollateral(WETHAddress, 1e18);
            uint256  _amountQualaterized = protocol.gets_addressToCollateralDeposited(owner, WETHAddress);
            assertEq(_amountQualaterized, 1e18);
    }


    function testUser_CanCreate_TwoRequest() public {
        testDepositTCollateral();
            uint256 requestAmount = 1e18;
            uint8 interestRate = 5;
            uint256 returnDate = block.timestamp + 365 days;  // 1 year later

            protocol.createLendingRequest(WETHAddress, requestAmount, interestRate, returnDate, diaToken);
            protocol.createLendingRequest(WETHAddress, requestAmount, interestRate, returnDate, diaToken);

            // Verify that the request is correctly added
            Protocol.Request[] memory requests = protocol.getAllRequest();
            assertEq(requests.length, 2);
            assertEq(requests[0].amount, requestAmount);
    }


    function testExcessiveBorrowing() public {
        testDepositTCollateral();
        uint256 requestAmount = 50e18;
        uint8 interestRate = 5;
        uint256 returnDate = block.timestamp + 365 days;  // 1 year later

        protocol.createLendingRequest(WETHAddress, requestAmount, interestRate, returnDate, diaToken);

        // Verify that the request is correctly added
        Protocol.Request[] memory requests = protocol.getAllRequest();
        assertEq(requests.length, 1);
        assertEq(requests[0].amount, requestAmount);
    }

    // function testUser_CanGiveOffer_ToRequest() public{
        
    // }




// function test_user_detail() public {

//     // testDepositQualateral();
//     switchSigner(owner);
//     uint total = protocol.getAccountCollateralValue(owner);
//     emit log("##########", total);



// }

// function testExcessiveBorrowing() public {

//     IERC20(WETHAddress).transfer(owner, 1 ether);
//     protocol.depositCollateral(WETHAddress, 1 ether);

//     uint256 eightyFivePercentOfCollateral = 1700e18; // 85% of $2000

//     uint256 excessiveLoanAmount = 1800e18;

//     // Capture the revert
//     // vm.expectRevert(bytes("Protocol__InsufficientCollateral"));
//     protocol.createLendingRequest(WETHAddress,excessiveLoanAmount,5,block.timestamp + 365 days, diaToken);
// }



// function testMultipleLendingRequests() public {
//     testDepositQualateral();

//     // First request: 50% of the collateral
//     protocol.createLendingRequest(WETHAddress, 3000e18, interestRate, returnDate, diaToken);
//     protocol.createLendingRequest(WETHAddress, , interestRate, returnDate, diaToken);


//     // Second request: 10% of the collateral
//     // protocol.createLendingRequest(WETHAddress, 10000, 5, returnDate, diaToken);

//     // Total borrowed so far: 60% which is below 85%
//     uint _length = protocol.getAllRequest().length;
//     assertEq(_length, 2);

//     // This request would bring the total to 100%, which should fail since it exceeds the 85% limit
//     vm.expectRevert(abi.encodeWithSelector(Protocol__InsufficientCollateral.selector));
//     // protocol.createLendingRequest(WETHAddress, 5000, 5, returnDate, diaToken);
// }







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




// function setUp() public {
//     owner = vm.addr(1);
//     address alice = vm.addr(2);

//     vm.startPrank(owner);
//     peerToken = new PeerToken(owner);
//     protocol = new Protocol();

//     tokens.push(WETHAddress);
//     tokens.push(diaToken);

//     priceFeed.push(DAI_ETH); // Mock address representing ETH/USD feed
//     priceFeed.push(DAI_USD); // Mock address representing DAI/USD feed

//     protocol.initialize(owner, tokens, priceFeed, address(peerToken));
//     IERC20(WETHAddress).approve(address(protocol), type(uint256).max);
//     IERC20(diaToken).approve(address(protocol), type(uint256).max);

//     vm.stopPrank();
// }