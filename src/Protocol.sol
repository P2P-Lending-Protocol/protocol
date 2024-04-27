// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {SimToken as PeerToken} from "./SimToken.sol";
import "./Libraries/Constant.sol";
import "./Libraries/Errors.sol";
import "./Libraries/Event.sol";


/// @title The Proxy Contract for the protocol
/// @author Benjamin Faruna, Favour Aniogor
/// @notice This uses the EIP1822 UUPS standard from the opwnzeppelin library
contract Protocol is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    ////////////////////////
    // STATE VARIABLES   //
    //////////////////////

    /// @dev Our utility Token $PEER TODO: import the PEER Token Contract
    PeerToken private s_PEER;

    /// @dev maps collateral token to their price feed
    mapping(address token => address priceFeed) private s_priceFeeds;
    /// @dev maps user to the value of balance he has collaterised
    mapping(address => mapping(address token => uint256 balance))
        private s_addressToCollateralDeposited;
    ///@dev mapping the address of a user to its Struct
    mapping(address => User) private addressToUser;

    mapping(address user => mapping(uint96 requestId => Request)) private request;
    /// @dev Collection of all colleteral Adresses
    address[] private s_collateralToken;
    /// @dev Collection of all all the resquest;
    Request [] private s_requests;
    /// @dev request id;
    uint96  private requestId;

    mapping(address user => uint256 amount) private amountRequested;
    mapping(address lender => uint256 amount) private amountUserIsLending;




    ///////////////
    /// EVENTS ///
    /////////////
    event CollateralDeposited(
        address indexed _sender,
        address indexed _token,
        uint256 _value
    );

    /////////////////////
    ///     ENUMS    ///
    ////////////////////
    enum Status {
        OPEN,
        SERVICED,
        CLOSED
    }

    enum OfferStatus{
        OPEN,
        REJECTED,
        ACCEPTED
    }

    ////////////////////
    ///   Structs    ///
    ///////////////////
    struct User {
        string email;
        bool isVerified;
    }
    struct Request {
        address tokenAddr;
        address author;
        uint256 amount;
        uint8 interest;
        Offer [] offer;
        uint256 returnDate;
        Status status;
    }

    struct Offer {
        uint256 offerId;
        address tokenAddr;
        address author;
        uint256 amount;
        uint8 interest;
        uint256 returnDate;
        OfferStatus offerStatus;
    }

    ///////////////////
    ///  MODIFIERS ///
    /////////////////
    modifier moreThanZero(uint256 _amount) {
        if (_amount <= 0) {
            revert Protocol__MustBeMoreThanZero();
        }
        _;
    }
    modifier isTokenAllowed(address _token) {
        if (s_priceFeeds[_token] == address(0)) {
            revert Protocol__TokenNotAllowed();
        }
        _;
    }

    //////////////////
    /// FUNCTIONS ///
    ////////////////

    /// @param _tokenCollateralAddress The address of the token to deposit as collateral
    /// @param _amountOfCollateral The amount of collateral to deposit
    function depositCollateral(
        address _tokenCollateralAddress,
        uint256 _amountOfCollateral
    )
        external
        moreThanZero(_amountOfCollateral)
        isTokenAllowed(_tokenCollateralAddress)
    {
        s_addressToCollateralDeposited[msg.sender][
            _tokenCollateralAddress
        ] += _amountOfCollateral;
        emit CollateralDeposited(
            msg.sender,
            _tokenCollateralAddress,
            _amountOfCollateral
        );
        bool _success = IERC20(_tokenCollateralAddress).transferFrom(
            msg.sender,
            address(this),
            _amountOfCollateral
        );
        if (!_success) {
            revert Protocol__TransferFailed();
        }
    }

    function gets_addressToCollateralDeposited(address _sender, address tokenAddr) external view returns (uint256) {
        return s_addressToCollateralDeposited[_sender][tokenAddr];
    }


    /// @notice Creates a request for a loan
    /// @param _collateralAddr Address of the collateral token
    /// @param _amount Amount of the loan
    /// @param _interest Interest rate of the loan
    /// @param _returnDate Expected date of loan repayment
  function createLendingRequest (
    address _collateralAddr,
    uint256 _amount,
    uint8 _interest,
    uint256 _returnDate
    )
    external
    moreThanZero(_amount) 
    moreThanZero(_interest)
{
    requestId = requestId + 1;
    uint256 _requiredCollateralToSpend = (s_addressToCollateralDeposited[msg.sender][_collateralAddr] * 85) / 100;

    // Check the new total request against the maximum allowable amount
    uint256 newTotalRequest = amountRequested[msg.sender] + _amount;
    if (newTotalRequest > _requiredCollateralToSpend) {
        revert Protocol__InsufficientCollateral();
    }

    // Update the total requested amount
    amountRequested[msg.sender] = newTotalRequest;

    // Create and store the new request
    Request storage _newRequest = request[msg.sender][requestId];
    _newRequest.author = msg.sender;
    _newRequest.tokenAddr =  _collateralAddr;
    _newRequest.amount = _amount;
    _newRequest.interest = _interest;
    _newRequest.returnDate = _returnDate;
    _newRequest.status = Status.OPEN;
    s_requests.push(_newRequest);

    emit RequestCreated(msg.sender, requestId, _amount, _interest);
}

    function getAllRequest() external view returns(Request [] memory){
        return s_requests;
    }


    /// @notice Allows a lender to make an offer to a lending request
    /// @param _borrower Address of the borrower who created the request
    /// @param _requestId Unique identifier for the lending request
    /// @param _amount Amount of money the lender is willing to lend
    /// @param _interest Interest rate proposed by the lender
    /// @param _returnedDate Expected return date for the lent amount
    /// @param _tokenAddress Address of the token in which the loan is denominated
    function makeLendingOffer(
        address _borrower,
        uint96 _requestId,
        uint256  _amount,
        uint8 _interest,
        uint256 _returnedDate,
        address _tokenAddress) 
        external
        moreThanZero(_amount)
        moreThanZero(_interest)
        {

        Request storage _foundRequest =  request[_borrower][_requestId];
        if(_foundRequest.status != Status.OPEN)  revert Protocol__RequestNotOpen();       
        if(IERC20(_tokenAddress).balanceOf(msg.sender) < _amount) revert  Protocol__InsufficientBalance();

        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);
        
        amountUserIsLending[msg.sender] = _amount;

        Offer memory _offer;
        _offer.offerId = _offer.offerId + 1;
        _offer.author = msg.sender;
        _offer.interest = _interest;
        _offer.tokenAddr = _tokenAddress;
        _offer.returnDate = _returnedDate;
        _offer.offerStatus = OfferStatus.OPEN;
        _offer.amount = _amount;
        _foundRequest.offer.push(_offer);

        emit OfferCreated(msg.sender,_tokenAddress,  _amount, _requestId);

    }

    /// @notice Responds to an offer for a lending request
    /// @param _requestId Identifier of the request to which the offer was made
    /// @param _offerId Identifier of the specific offer being responded to
    /// @param _status New status of the offer, can be ACCEPTED or REJECTED
    function respondToLendingOffer(
        uint96 _requestId, 
        uint256 _offerId, 
        OfferStatus _status
    ) external {
    // Fetch the request and offer
        Request storage _foundRequest = request[msg.sender][_requestId];
        if(_foundRequest.status != Status.OPEN) revert Protocol__RequestNotOpen();
        if(_offerId > _foundRequest.offer.length) revert Protocol__InvalidId();

            Offer storage _foundOffer = _foundRequest.offer[_offerId];

        if (_foundOffer.offerStatus != OfferStatus.OPEN) revert Protocol__OfferNotOpen();

            // Update the offer status
            _foundOffer.offerStatus = _status;

        // Handle accepted offer
        if (_status == OfferStatus.ACCEPTED) {
            uint256 _amountToLend = amountUserIsLending[_foundOffer.author];
            
            amountUserIsLending[_foundOffer.author] = 0;
            IERC20(_foundOffer.tokenAddr).transfer(msg.sender, _amountToLend);
            _foundRequest.status = Status.SERVICED;

            // Handle multiple offers
                for (uint _index = 0; _index < _foundRequest.offer.length; _index++) {
                    if(_index != _offerId){
                        Offer storage otherOffer = _foundRequest.offer[_index];
                        uint256 otherAmountToLend = amountUserIsLending[otherOffer.author];
                        amountUserIsLending[otherOffer.author] = 0;
                        IERC20(otherOffer.tokenAddr).transfer(otherOffer.author, otherAmountToLend);

                    }
                }
            }
        // Handle rejected offer
        else if (_status == OfferStatus.REJECTED) {
            uint256 amountToLend = amountUserIsLending[_foundOffer.author];
            amountUserIsLending[_foundOffer.author] = 0;
            IERC20(_foundOffer.tokenAddr).transfer(msg.sender, amountToLend);
        }

    emit RespondToLendingOffer(msg.sender, _offerId, uint8(_foundRequest.status), uint8(_foundOffer.offerStatus));
    }


    /// @notice Directly services a lending request by transferring funds to the borrower
    /// @param _borrower Address of the borrower to receive the funds
    /// @param _requestId Identifier of the request being serviced
    /// @param _tokenAddress Token in which the funds are being transferred
    function serviceRequest(
        address _borrower, 
        uint8 _requestId, 
        address _tokenAddress)
         external 
         {

        Request storage _foundRequest = request[_borrower][_requestId];

        if (_foundRequest.status != Status.OPEN) revert Protocol__RequestNotOpen();
        uint256 amountToLend =   _foundRequest.amount;
        
        if(IERC20(_tokenAddress).balanceOf(msg.sender) < amountToLend)
         revert  Protocol__InsufficientBalance();
         
        IERC20(_tokenAddress).transferFrom(msg.sender, _borrower, amountToLend);
        _foundRequest.status = Status.SERVICED;
        emit ServiceRequestSuccessful(msg.sender, _borrower, _requestId);
    }




    ///////////////////////
    /// VIEW FUNCTIONS ///
    //////////////////////

    /// @notice Checks the health Factor which is a way to check if the user has enough collateral to mint
    /// @param _user a parameter for the address to check
    /// @return uint256 returns the health factor which is supoose to be >= 1
    function _healthFactor(address _user) private view returns (uint256) {

        (
            uint256 _totalBurrowInUsd,
            uint256 _collateralValueInUsd
        ) = _getAccountInfo(_user);
        uint256 _collateralAdjustedForThreshold = (_collateralValueInUsd *
            Constants.LIQUIDATION_THRESHOLD) / 100;
        return
            (_collateralAdjustedForThreshold * Constants.PRECISION) /
            _totalBurrowInUsd;
    }

    function getAllCollateralToken() external view returns(address [] memory) {
        return s_collateralToken;
    }

    /// @notice This checks the health factor to see if  it is broken if it is it reverts
    /// @param _user a parameter for the address we want to check the health factor for
    function _revertIfHealthFactorIsBroken(address _user) internal view {
        uint256 _userHealthFactor = _healthFactor(_user);
        if (_userHealthFactor < Constants.MIN_HEALTH_FACTOR) {
            revert Protocol__BreaksHealthFactor();
        }
    }

    /// @notice This gets the amount of collateral a user has deposited in USD
    /// @param _user the address who you want to get their collateral value
    /// @return _totalCollateralValueInUsd returns the value of the user deposited collateral in USD
    function getAccountCollateralValue(
        address _user
    ) public view returns (uint256 _totalCollateralValueInUsd) {
        for (uint256 index = 0; index < s_collateralToken.length; index++) {
            address _token = s_collateralToken[index];
            uint256 _amount = s_addressToCollateralDeposited[_user][_token];
            _totalCollateralValueInUsd += getUsdValue(_token, _amount);
        }
    }

    /// @notice This gets the USD value of amount of the token passsed.
    /// @dev This uses chainlinks AggregatorV3Interface to get the price with the pricefeed address.
    /// @param _token a collateral token address that is allowed in our Smart Contract
    /// @param _amount the amount of that token you want to get the USD equivalent of.
    /// @return uint256 returns the equivalent amount in USD.
    function getUsdValue(
        address _token,
        uint256 _amount
    ) public view returns (uint256) {
        AggregatorV3Interface _priceFeed = AggregatorV3Interface(
            s_priceFeeds[_token]
        );
        (, int256 _price, , , ) = _priceFeed.latestRoundData();
        return
            ((uint256(_price) * Constants.NEW_PRECISION) * _amount) /
            Constants.PRECISION;
    }

    /// @notice This gets the account info of any account
    /// @param _user a parameter for the user account info you want to get
    /// @return _totalBurrowInUsd returns the total amount of SC the  user has minted
    /// @return _collateralValueInUsd returns the total collateral the user has deposited in USD
    function _getAccountInfo(
        address _user
    )
        private
        view
        returns (uint256 _totalBurrowInUsd, uint256 _collateralValueInUsd)
    {
        _totalBurrowInUsd = 0; //TODO: create a function to get this
        _collateralValueInUsd = getAccountCollateralValue(_user);
    }

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
            revert Protocol__tokensAndPriceFeedsArrayMustBeSameLength();
        }
        for (uint8 i = 0; i < _tokens.length; i++) {
            s_priceFeeds[_tokens[i]] = _priceFeeds[i];
            s_collateralToken.push(_tokens[i]);
        }
        s_PEER = PeerToken(_peerAddress);
    }

    /// @dev Assist with upgradable proxy
    /// @param {address} a parameter just like in doxygen (must be followed by parameter name)
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
// interface Protocol {
//     function depositCollateral();
//     function redeemCollateral();
//     function createRequest();
//     function createOffer();

//     function serliquidateUserviceRequest();
//     function ();
//     function tokenCollateral();
// }
