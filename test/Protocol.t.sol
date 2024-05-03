// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {PeerToken} from "../src/PeerToken.sol";
import {Protocol} from "../src/Protocol.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IProtocolTest} from "./IProtocolTest.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "../src/Libraries/Errors.sol";

contract ProtocolTest is Test, IProtocolTest {
    PeerToken private peerToken;
    Protocol public protocol;
    address[] tokens;
    address[] priceFeed;

    address owner = address(0xa);
    address B = address(0xb);
    address C = address(0xc);

    event log(string message, Protocol.Offer[] _twoOffers);

    address diaToken = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    // address USDCAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address WETHAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address avaxToken = 0x85f138bfEE4ef8e540890CFb48F620571d67Eda3;

    address WETH_USD = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address DAI_USD = 0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9;
    address AVAX_USD = 0xFF3EEb22B5E3dE6e705b44749C2559d704923FD7;

    function setUp() public {
        owner = mkaddr("owner");
        switchSigner(owner);
        B = mkaddr("B address");
        C = mkaddr("C address");
        peerToken = new PeerToken(owner);
        protocol = new Protocol();

        // tokens.punsh(USDCAddress);
        tokens.push(diaToken);
        tokens.push(WETHAddress);
        tokens.push(avaxToken);

        priceFeed.push(DAI_USD);
        priceFeed.push(WETH_USD);
        priceFeed.push(AVAX_USD);
        // priceFeed.push(USDCAddre
        protocol.initialize(owner, tokens, priceFeed, address(peerToken));
        IERC20(WETHAddress).approve(address(protocol), type(uint).max);
        IERC20(diaToken).approve(address(protocol), type(uint).max);
    }

    function testDepositTCollateral() public {
        // protocol.initialize(owner,tokens, priceFeed, address(peerToken));
        switchSigner(WETHAddress);
        // console.log("balance is ::: ",IERC20(diaToken).balanceOf(address(0)));
        IERC20(WETHAddress).transfer(owner, 1 ether);

        switchSigner(owner);
        protocol.depositCollateral(WETHAddress, 1e18);
        uint256 _amountQualaterized = protocol
            .gets_addressToCollateralDeposited(owner, WETHAddress);
        assertEq(_amountQualaterized, 1e18);
    }

    function testUser_CanCreate_TwoRequest() public {
        testDepositTCollateral();
        switchSigner(owner);

        uint256 requestAmount = 1e18;
        uint8 interestRate = 5;
        uint256 returnDate = block.timestamp + 365 days;

        protocol.createLendingRequest(
            WETHAddress,
            requestAmount,
            interestRate,
            returnDate,
            diaToken
        );
        protocol.createLendingRequest(
            WETHAddress,
            requestAmount,
            interestRate,
            returnDate,
            diaToken
        );

        // Verify that the request is correctly added
        Protocol.Request[] memory requests = protocol.getAllRequest();
        assertEq(requests.length, 2);
        assertEq(requests[0].amount, requestAmount);
    }

    function testExcessiveBorrowing() public {
        testDepositTCollateral();
        uint256 requestAmount = 3000e18;
        uint8 interestRate = 5;
        uint256 returnDate = block.timestamp + 365 days; // 1 year later

        vm.expectRevert(
            abi.encodeWithSelector(Protocol__InsufficientCollateral.selector)
        );
        protocol.createLendingRequest(
            WETHAddress,
            requestAmount,
            interestRate,
            returnDate,
            diaToken
        );

        vm.expectRevert(
            abi.encodeWithSelector(Protocol__InsufficientCollateral.selector)
        );
        protocol.createLendingRequest(
            WETHAddress,
            100e18,
            interestRate,
            returnDate,
            avaxToken
        );
    }

    function testUser_CanGiveOffer_ToRequest() public {
        testUser_CanCreate_TwoRequest();

        // note test user can give one offer to 1 request
        // switchSigner(B);
        switchSigner(diaToken);
        IERC20(diaToken).transfer(B, 10e18);
        switchSigner(B);
        IERC20(diaToken).approve(address(protocol), type(uint).max);
        protocol.makeLendingOffer(
            owner,
            1,
            1e18,
            7,
            block.timestamp + 10 days,
            diaToken
        );
        Protocol.Offer[] memory offers = protocol.getAllOfferForUser(owner, 1);
        assertEq(offers.length, 1);

        //note TEST another user can give another offer  to  request with ID ONE

        switchSigner(diaToken);
        IERC20(diaToken).transfer(C, 10e18);
        switchSigner(C);
        IERC20(diaToken).approve(address(protocol), type(uint).max);
        protocol.makeLendingOffer(
            owner,
            1,
            1e18,
            8,
            block.timestamp + 20 days,
            diaToken
        );
        Protocol.Offer[] memory _twoOffers = protocol.getAllOfferForUser(
            owner,
            1
        );
        emit log("**************!!!!!", _twoOffers);
        assertEq(_twoOffers.length, 2);

        //note TEST user can give another offer  to  request with ID TWO
        switchSigner(diaToken);
        IERC20(diaToken).transfer(B, 10e18);
        switchSigner(B);
        IERC20(diaToken).approve(address(protocol), type(uint).max);
        protocol.makeLendingOffer(
            owner,
            2,
            1e18,
            7,
            block.timestamp + 10 days,
            diaToken
        );
        Protocol.Offer[] memory _Id2RequestOfferList = protocol
            .getAllOfferForUser(owner, 2);
        assertEq(_Id2RequestOfferList.length, 1);

        //note TEST user can give another offer  to  request with ID TWO
        switchSigner(diaToken);
        IERC20(diaToken).transfer(C, 10e18);
        switchSigner(C);
        IERC20(diaToken).approve(address(protocol), type(uint).max);
        protocol.makeLendingOffer(
            owner,
            2,
            1e18,
            8,
            block.timestamp + 20 days,
            diaToken
        );
        Protocol.Offer[] memory _Id2Request_OfferList = protocol
            .getAllOfferForUser(owner, 2);
        emit log("**************!!!!!", _Id2Request_OfferList);
        assertEq(_Id2Request_OfferList.length, 2);
    }

    // function testMultiple_UserCanGive_OfferToOneRequest() public {

    //     testUser_CanCreate_TwoRequest();

    //     switchSigner(diaToken);
    //     IERC20(diaToken).transfer(B, 10e18);

    //     switchSigner(B);
    //     IERC20(diaToken).approve(address(protocol), type(uint).max);
    //     protocol.makeLendingOffer(owner, 1, 1e18, 7, block.timestamp + 10 days, diaToken);
    //     Protocol.Offer [] memory offers =  protocol.getAllOfferForUser(owner,1);
    //     assertEq(offers.length, 1);

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

    function test_serviceRequest() public {
        IERC20 wethContract = IERC20(WETHAddress);
        switchSigner(WETHAddress);
        // console.log("balance is ::: ",IERC20(diaToken).balanceOf(address(0)));
        wethContract.transfer(B, 100e18);
        testDepositTCollateral();
        uint256 requestAmount = 50e18;
        uint8 interestRate = 5;
        uint256 returnDate = block.timestamp + 365 days; // 1 year later

        uint256 borrowerWETHStartBalance = wethContract.balanceOf(owner);

        protocol.createLendingRequest(
            WETHAddress,
            requestAmount,
            interestRate,
            returnDate,
            diaToken
        );

        switchSigner(B);
        wethContract.approve(address(protocol), requestAmount);
        protocol.serviceRequest(owner, 1, WETHAddress);
        assertEq(
            wethContract.balanceOf(owner),
            borrowerWETHStartBalance + requestAmount
        );
        Protocol.Request memory _borrowRequest = protocol.getUserRequest(
            owner,
            1
        );
        assertEq(uint8(_borrowRequest.status), uint8(1));
    }

    function test_serviceRequestFailsAfterFirstService() public {
        IERC20 wethContract = IERC20(WETHAddress);
        switchSigner(WETHAddress);
        // console.log("balance is ::: ",IERC20(diaToken).balanceOf(address(0)));
        wethContract.transfer(B, 100e18);
        testDepositTCollateral();
        uint256 requestAmount = 50e18;
        uint8 interestRate = 5;
        uint256 returnDate = block.timestamp + 365 days; // 1 year later

        protocol.createLendingRequest(
            WETHAddress,
            requestAmount,
            interestRate,
            returnDate,
            diaToken
        );

        switchSigner(B);
        wethContract.approve(address(protocol), requestAmount);
        protocol.serviceRequest(owner, 1, WETHAddress);

        vm.expectRevert(
            abi.encodeWithSelector(Protocol__RequestNotOpen.selector)
        );
        protocol.serviceRequest(owner, 1, WETHAddress);

        // to ensure it is not just the first person to service the request it fails for
        switchSigner(C);
        vm.expectRevert(
            abi.encodeWithSelector(Protocol__RequestNotOpen.selector)
        );
        protocol.serviceRequest(owner, 1, WETHAddress);
    }

    function test_serviceRequestFailsWithoutTokenAllowance() public {
        IERC20 wethContract = IERC20(WETHAddress);
        switchSigner(WETHAddress);
        wethContract.transfer(B, 100e18);
        testDepositTCollateral();
        uint256 requestAmount = 50e18;
        uint8 interestRate = 5;
        uint256 returnDate = block.timestamp + 365 days; // 1 year later

        protocol.createLendingRequest(
            WETHAddress,
            requestAmount,
            interestRate,
            returnDate,
            diaToken
        );

        switchSigner(B);
        // wethContract.approve(address(protocol), requestAmount);
        vm.expectRevert(
            abi.encodeWithSelector(Protocol__InsufficientAllowance.selector)
        );
        protocol.serviceRequest(owner, 1, WETHAddress);
    }

    function test_serviceRequestFailsWithoutEnoughBalance() public {
        IERC20 wethContract = IERC20(WETHAddress);
        switchSigner(WETHAddress);
        wethContract.transfer(B, 49e18);
        testDepositTCollateral();
        uint256 requestAmount = 50e18;
        uint8 interestRate = 5;
        uint256 returnDate = block.timestamp + 365 days; // 1 year later

        protocol.createLendingRequest(
            WETHAddress,
            requestAmount,
            interestRate,
            returnDate,
            diaToken
        );

        switchSigner(B);
        wethContract.approve(address(protocol), requestAmount);
        vm.expectRevert(
            abi.encodeWithSelector(Protocol__InsufficientBalance.selector)
        );
        protocol.serviceRequest(owner, 1, WETHAddress);
    }

    // function test_addCollateralTokens() public {
    //     address[] memory _tokens = new address[](5);
    //     address[] memory _priceFeed = new address[](5);

    //     address[] memory _collateralTokens = protocol.getAllCollateralToken();

    //     for (uint256 i = 0; i < 5; i++) {
    //         _tokens[i] = mkaddr(string(abi.encodePacked("Token", i)));
    //         _priceFeed[i] = mkaddr(string(abi.encodePacked("priceFeed", i)));
    //     }
    //     protocol.addCollateralTokens(_tokens, _priceFeed);

    //     protocol.getAllCollateralToken();

    //     assertEq(
    //         protocol.getAllCollateralToken().length,
    //         _collateralTokens.length + 5
    //     );
    // }

    // function test_removeCollateralTokens() public {
    //     test_addCollateralTokens();
    //     address[] memory _tokens = new address[](5);
    //     address[] memory _priceFeed = new address[](5);

    //     address[] memory _collateralTokens = protocol.getAllCollateralToken();

    //     for (uint256 i = 0; i < 5; i++) {
    //         _tokens[i] = mkaddr(string(abi.encodePacked("Token", i)));
    //         _priceFeed[i] = mkaddr(string(abi.encodePacked("priceFeed", i)));
    //     }

    //     protocol.removeCollateralTokens(_tokens);

    //     assertEq(
    //         protocol.getAllCollateralToken().length,
    //         _collateralTokens.length - 5
    //     );
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
