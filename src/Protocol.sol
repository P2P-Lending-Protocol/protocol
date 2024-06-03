// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import {PeerToken} from "./PeerToken.sol";
import "./Libraries/Constant.sol";
import "./Libraries/Errors.sol";
import "./Libraries/Event.sol";

/// @title The Proxy Contract for the protocol
/// @author Benjamin Faruna, Favour Aniogor
/// @notice This uses the EIP1822 UUPS standard from the opwnzeppelin library
contract Protocol is Initializable, OwnableUpgradeable, UUPSUpgradeable, ChainlinkClient {
        using Chainlink for Chainlink.Request;
    ////////////////////////
    // STATE VARIABLES   //
    //////////////////////


    /// @dev Our utility Token $PEER TODO: import the PEER Token Contract
    PeerToken private s_PEER;

    /// @dev maps collateral token to their price feed
    mapping(address token => address priceFeed) private s_priceFeeds;
    /// @dev maps address of a token to see if it is loanable
    mapping(address token => bool isLoanable) private s_isLoanable;
    /// @dev maps user to the value of balance he has collaterised
    mapping(address => mapping(address token => uint256 balance))
        private s_addressToCollateralDeposited;
    ///@dev mapping the address of a user to its Struct
    mapping(address => User) private addressToUser;
    ///@dev mapping of users to their address
    mapping(address user => mapping(uint96 requestId => Request))
        private request;
    /// @dev Collection of all colleteral Adresses
    address[] private s_collateralToken;
    /// @dev all loanable assets
    address[] private s_loanableToken;
    /// @dev Collection of all all the resquest;
    Request[] private s_requests;
    /// @dev request id;
    uint96 private requestId;

    // mapping(address user => uint256 amount) private amountRequested;
    mapping(address lender => uint256 amount) private amountUserIsLending;

    mapping(address => mapping(address => uint256)) private userloanAmount;

    mapping(address => uint256) private amountLoaned;

    address private oracleAddress;
    bytes32 private jobId;
    uint256 private fee;
    uint256 public response;
    

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

    enum OfferStatus {
        OPEN,
        REJECTED,
        ACCEPTED
    }

    ////////////////////
    ///   Structs    ///
    ///////////////////
    struct User {
        string email;
        address userAddr;
        bool isVerified;
        uint gitCoinPoint;
        uint totalLoanCollected;
    }
    struct Request {
        uint96 requestId;
        address author;
        uint256 amount;
        uint8 interest;
        uint256 _totalRepayment;
        Offer[] offer;
        uint256 returnDate;
        address lender;
        address loanRequestAddr;
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
        checkIsVerified(msg.sender);
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

  

    /**
     * @notice Creates a request for a loan
     * @param _amount The principal amount of the loan
     * @param _interest The annual interest rate of the loan (in percentage points)
     * @param _returnDate The unix timestamp by when the loan should be repaid
     * @param _loanCurrency The currency in which the loan is denominated
     * @dev This function calculates the required repayments and checks the borrower's collateral before accepting a loan request.
     */
    function createLendingRequest(
        uint256 _amount,
        uint8 _interest,
        uint256 _returnDate,
        address _loanCurrency
    ) external moreThanZero(_amount) {
        if (!s_isLoanable[_loanCurrency]) {
            revert Protocol__TokenNotLoanable();
        }
        checkIsVerified(msg.sender);
        uint256 _loanUsdValue = getUsdValue(_loanCurrency, _amount);
        if (_loanUsdValue < 1) revert Protocol__InvalidAmount();

        uint256 collateralValueInLoanCurrency = getAccountCollateralValue(
            msg.sender
        );
        uint256 maxLoanableAmount = (collateralValueInLoanCurrency * 85) / 100;

        if (
            addressToUser[msg.sender].totalLoanCollected + _loanUsdValue >=
            maxLoanableAmount
        ) {
            revert Protocol__InsufficientCollateral();
        }

        requestId++;
        Request storage _newRequest = request[msg.sender][requestId];
        _newRequest.requestId = requestId;
        _newRequest.author = msg.sender;
        _newRequest.amount = _amount;
        _newRequest.interest = _interest;
        _newRequest.returnDate = _returnDate;
        _newRequest._totalRepayment = _calculateLoanInterest(
            _returnDate,
            _amount,
            _interest,
            _loanCurrency
        );
        _newRequest.loanRequestAddr = _loanCurrency;
        _newRequest.status = Status.OPEN;
        s_requests.push(_newRequest);

        emit RequestCreated(msg.sender, requestId, _amount, _interest);
    }

    function repayLoan(uint96 _requestId, uint256 _amount) public {
        checkIsVerified(msg.sender);
        string memory _email = addressToUser[msg.sender].email;

        _sendMailRepayLoan(_email);
        Request storage _foundRequest = request[msg.sender][_requestId];
        uint256 _repaymentValueUsd = getUsdValue(
            _foundRequest.loanRequestAddr,
            _amount
        );
        if (_foundRequest.status != Status.SERVICED)
            revert Protocol__RequestNotServiced();

        IERC20 _loanToken = IERC20(_foundRequest.loanRequestAddr);
        if (_loanToken.balanceOf(msg.sender) < _amount)
            revert Protocol__InsufficientBalance();

        // protocol only pays what is remaining without taking excess user token
        if (_foundRequest._totalRepayment >= _repaymentValueUsd) {
            _foundRequest._totalRepayment -= _repaymentValueUsd;
        } else {
            _repaymentValueUsd = _foundRequest._totalRepayment;
            _foundRequest._totalRepayment = 0;
        }

        if (_foundRequest._totalRepayment == 0) {
            _foundRequest.status = Status.CLOSED;
        }

        _loanToken.transferFrom(msg.sender, _foundRequest.lender, _amount);

        // uint256 _repaymentValueUsd = getUsdValue(_foundRequest.tokenAddr, _amount);

        // userloanAmount[msg.sender][_foundRequest.tokenAddr] -= _amount;

        emit LoanRepayment(msg.sender, _requestId, _amount);
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
        uint256 _amount,
        uint8 _interest,
        uint256 _returnedDate,
        address _tokenAddress
    ) external moreThanZero(_amount) moreThanZero(_interest) {
        checkIsVerified(msg.sender);
        string memory _email = addressToUser[msg.sender].email;

        _sendEmailOfferRequest(_email, _amount, _interest, _returnedDate);
        Request storage _foundRequest = request[_borrower][_requestId];
        if (_foundRequest.status != Status.OPEN)
            revert Protocol__RequestNotOpen();
        if (IERC20(_tokenAddress).balanceOf(msg.sender) < _amount)
            revert Protocol__InsufficientBalance();
        if (_foundRequest.loanRequestAddr != _tokenAddress)
            revert Protocol__InvalidToken();

        IERC20(_tokenAddress).approve(address(this), _amount);

        Offer memory _offer;
        _offer.offerId = _offer.offerId + 1;
        _offer.author = msg.sender;
        _offer.interest = _interest;
        _offer.tokenAddr = _tokenAddress;
        _offer.returnDate = _returnedDate;
        _offer.offerStatus = OfferStatus.OPEN;
        _offer.amount = _amount;
        _foundRequest.offer.push(_offer);

        emit OfferCreated(msg.sender, _tokenAddress, _amount, _requestId);
    }

    /// @notice Responds to an offer for a lending request
    /// @param _requestId Identifier of the request to which the offer was made
    /// @param _offerId Identifier of the specific offer being responded to
    /// @param _status New status of the offer, can be ACCEPTED or REJECTED
    function respondToLendingOffer(
        uint96 _requestId,
        uint96 _offerId,
        OfferStatus _status
    ) external {
        checkIsVerified(msg.sender);
        Request storage _foundRequest = request[msg.sender][_requestId];
        if (_foundRequest.status != Status.OPEN)
            revert Protocol__RequestNotOpen();

        if (_offerId > _foundRequest.offer.length) revert Protocol__InvalidId();

        Offer storage _foundOffer = _foundRequest.offer[_offerId];
        if (_foundOffer.offerStatus != OfferStatus.OPEN)
            revert Protocol__OfferNotOpen();

        if (msg.sender != _foundRequest.author) revert Protocol__Unauthorized();

        _foundOffer.offerStatus = _status;

        if (_status == OfferStatus.ACCEPTED) {
            _handleAcceptedOffer(_foundRequest, _foundOffer, _offerId);
        } else if (_status == OfferStatus.REJECTED) {
            _handleRejectedOffer(_foundOffer);
        }

        emit RespondToLendingOffer(
            msg.sender,
            _offerId,
            uint8(_foundRequest.status),
            uint8(_foundOffer.offerStatus)
        );
    }

    /// @dev For handling acccepting of offers
    /// @param _foundRequest the request a user made
    /// @param _foundOffer the Offer a Lender made
    /// @param _offerId the id of the Id
    function _handleAcceptedOffer(
        Request storage _foundRequest,
        Offer storage _foundOffer,
        uint96 _offerId
    ) internal {
        _foundRequest.lender = _foundOffer.author;
        _foundRequest.status = Status.SERVICED;
        _foundOffer.offerStatus = OfferStatus.ACCEPTED;
        // _foundRequest.disbursementTimestamp = block.timestamp;  // Timestamp for interest accrual start

        uint256 _totalRepayment = _calculateLoanInterest(
            _foundOffer.returnDate,
            _foundOffer.amount,
            _foundOffer.interest,
            _foundOffer.tokenAddr
        );
        _foundRequest._totalRepayment = _totalRepayment;
        // Update user's total obligation with the expected total repayment
        addressToUser[_foundRequest.author]
            .totalLoanCollected += _totalRepayment;

        if (_healthFactor(_foundRequest.author) < 1) {
            revert Protocol__InsufficientCollateral();
        }

        IERC20(_foundOffer.tokenAddr).transferFrom(
            _foundOffer.author,
            _foundRequest.author,
            _foundOffer.amount
        );

        emit OfferAccepted(_foundRequest.author, _offerId, _foundOffer.amount);
    }

    /// @dev handle the rejection of an offer
    /// @param _foundOffer the offer being sent
    function _handleRejectedOffer(Offer storage _foundOffer) internal {
        string memory _email = addressToUser[msg.sender].email;
        _sendMailRejectOffer(_email);
        _foundOffer.offerStatus = OfferStatus.REJECTED;
    }

    /// @notice Directly services a lending request by transferring funds to the borrower
    /// @param _borrower Address of the borrower to receive the funds
    /// @param _requestId Identifier of the request being serviced
    /// @param _tokenAddress Token in which the funds are being transferred
    function serviceRequest(
        address _borrower,
        uint8 _requestId,
        address _tokenAddress
    ) external {
        checkIsVerified(msg.sender);
        Request storage _foundRequest = request[_borrower][_requestId];
        string memory _email = addressToUser[msg.sender].email;

        _sendMailServiceLoan(_email);
        if (_foundRequest.status != Status.OPEN)
            revert Protocol__RequestNotOpen();
        if (_foundRequest.loanRequestAddr != _tokenAddress)
            revert Protocol__InvalidToken();

        _foundRequest.lender = msg.sender;
        _foundRequest.status = Status.SERVICED;
        uint256 amountToLend = _foundRequest.amount;

        // Check if the lender has enough balance and the allowance to transfer the tokens
        if (IERC20(_tokenAddress).balanceOf(msg.sender) < amountToLend)
            revert Protocol__InsufficientBalance();
        if (
            IERC20(_tokenAddress).allowance(msg.sender, address(this)) <
            amountToLend
        ) revert Protocol__InsufficientAllowance();

        uint256 _loanUsdValue = getUsdValue(_tokenAddress, amountToLend);

        uint256 _totalRepayment = _loanUsdValue +
            _calculateLoanInterest(
                _foundRequest.returnDate,
                _foundRequest.amount,
                _foundRequest.interest,
                _foundRequest.loanRequestAddr
            );
        _foundRequest._totalRepayment = _totalRepayment;
        addressToUser[_foundRequest.author]
            .totalLoanCollected += _totalRepayment;

        if (_healthFactor(_foundRequest.author) < 1) {
            revert Protocol__InsufficientCollateral();
        }

        // Transfer the funds from the lender to the borrower
        bool success = IERC20(_tokenAddress).transferFrom(
            msg.sender,
            _borrower,
            amountToLend
        );
        require(success, "Protocol__TransferFailed");

        // Update the request's status to serviced
        _foundRequest.status = Status.SERVICED;

        // Emit a success event with relevant details
        emit ServiceRequestSuccessful(
            msg.sender,
            _borrower,
            _requestId,
            amountToLend
        );
    }

    /// @notice Withdraws collateral from the protocol
    /// @param _tokenCollateralAddress Address of the collateral token
    /// @param _amount Amount of collateral to withdraw
    function withdrawCollateral(
        address _tokenCollateralAddress,
        uint256 _amount
    ) external moreThanZero(_amount) isTokenAllowed(_tokenCollateralAddress) {
        checkIsVerified(msg.sender);
        uint256 depositedAmount = s_addressToCollateralDeposited[msg.sender][
            _tokenCollateralAddress
        ];
        if (depositedAmount < _amount) {
            revert Protocol__InsufficientCollateralDeposited();
        }

        s_addressToCollateralDeposited[msg.sender][
            _tokenCollateralAddress
        ] -= _amount;

        // Check if remaining collateral still covers all loan obligations
        _revertIfHealthFactorIsBroken(msg.sender);

        bool success = IERC20(_tokenCollateralAddress).transfer(
            msg.sender,
            _amount
        );
        require(success, "Protocol__TransferFailed");

        emit CollateralWithdrawn(msg.sender, _tokenCollateralAddress, _amount);
    }

    /// @notice Adds new collateral tokens to the protocol
    /// @param _tokens Array of new collateral token addresses
    /// @param _priceFeeds Array of price feed addresses for the new collateral tokens
    function addCollateralTokens(
        address[] memory _tokens,
        address[] memory _priceFeeds
    ) external onlyOwner {
        checkIsVerified(msg.sender);
        if (_tokens.length != _priceFeeds.length) {
            revert Protocol__tokensAndPriceFeedsArrayMustBeSameLength();
        }
        for (uint8 i = 0; i < _tokens.length; i++) {
            s_priceFeeds[_tokens[i]] = _priceFeeds[i];
            s_collateralToken.push(_tokens[i]);
        }
        emit UpdatedCollateralTokens(
            msg.sender,
            uint8(s_collateralToken.length)
        );
    }

    /// @notice Removes collateral tokens from the protocol
    /// @param _tokens Array of collateral token addresses to remove
    function removeCollateralTokens(
        address[] memory _tokens
    ) external onlyOwner {
        checkIsVerified(msg.sender);
        for (uint8 i = 0; i < _tokens.length; i++) {
            s_priceFeeds[_tokens[i]] = address(0);
            for (uint8 j = 0; j < s_collateralToken.length; j++) {
                if (s_collateralToken[j] == _tokens[i]) {
                    s_collateralToken[j] = s_collateralToken[
                        s_collateralToken.length - 1
                    ];
                    s_collateralToken.pop();
                }
            }
        }
        emit UpdatedCollateralTokens(
            msg.sender,
            uint8(s_collateralToken.length)
        );
    }

    /// @dev For adding more tokens that are loanable on the platform
    /// @param _token the address of the token you want to be loanable on the protocol
    /// @param _priceFeed the address of the currency pair on chainlink
    function addLoanableToken(
        address _token,
        address _priceFeed
    ) external onlyOwner {
        checkIsVerified(msg.sender);
        s_isLoanable[_token] = true;
        s_priceFeeds[_token] = _priceFeed;
        s_loanableToken.push(_token);
        emit UpdateLoanableToken(_token, _priceFeed, msg.sender);
    }

    /// @dev for upating git coin post score
    /// @param _user the address to the user you want to update
    /// @param _score the gitcoin point score.
    function updateGPScore(address _user, uint256 _score) public onlyOwner {
        addressToUser[_user].gitCoinPoint = _score;
    }

     /// @dev for upating git coin post score
    /// @param _user the address to the user you want to update
    /// @param _email the email address of the user that verified
    /// @param _status the status is to verify that the user is verified
    function updateEmail(address _user, string memory _email, bool _status) public onlyOwner {
        addressToUser[_user].isVerified = _status;
        addressToUser[_user].email = _email;
    }

    function checkIsVerified(address _user) private view{
          if(!addressToUser[_user].isVerified) revert Protocol__EmailNotVerified();
    }

        // Update oracle address
    function setOracleAddress(address _oracleAddress) public onlyOwner {
        oracleAddress = _oracleAddress;
        _setChainlinkOracle(_oracleAddress);
    }


    // Update jobId
    function setJobId(string memory _jobId) public onlyOwner {
        jobId = bytes32(bytes(_jobId));
    }

    function setFeeInJuels(uint256 _feeInJuels) public onlyOwner {
        fee = _feeInJuels;
    }

    function setFeeInHundredthsOfLink(uint256 _feeInHundredthsOfLink) public onlyOwner {
        setFeeInJuels((_feeInHundredthsOfLink * LINK_DIVISIBILITY) / 100);
    }
  

   function _sendEmailOfferRequest(
        string memory _userEmail,
        uint256 _amount,
        uint8 _interest,
        uint256 _returnDate
    ) public {
        Chainlink.Request memory req = _buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        // Define the JSON payload
        string memory payload = string(abi.encodePacked(
            '{"userEmail":"', _userEmail,
            '","amount":', uint2str(_amount),
            ',"interest":', uint2str(_interest),
            ',"returnDate":"', uint2str(_returnDate),
            '"}'
        ));
        // Define the request parameters
        req._add("method", "POST");
        req._add("url", "https://email-service-backend-1.onrender.com/swagger-ui/index.html#/offer-controller/createOfferMail");
        req._add("headers", '["content-type", "application/json"]');
        req._add("body", payload);
        
        // Send the request to the Chainlink oracle
        _sendOperatorRequest(req, fee);
    }


    function _sendMailServiceLoan(string memory _email) public {

        Chainlink.Request memory req = _buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        string memory payload = string(abi.encodePacked('{"email":"', _email, '"}'));
        // Define the request parameters
        req._add("method", "POST");
        req._add("url", "https://email-service-backend-1.onrender.com/swagger-ui/index.html#/offer-controller/serviceLoanMail");
        req._add("headers", '["content-type", "application/json"]');
        req._add("body", payload);
        // Send the request to the Chainlink oracle
        _sendOperatorRequest(req, fee);
    }


    function _sendMailRejectOffer(string memory _email) public {

        Chainlink.Request memory req = _buildChainlinkRequest(jobId, address(this), this.fulfill.selector); 
        string memory payload = string(abi.encodePacked('{"email":"', _email, '"}'));
        req._add("method", "POST");
        req._add("url", "https://email-service-backend-1.onrender.com/swagger-ui/index.html#/offer-controller/rejectOfferMail");
        req._add("headers", '["content-type", "application/json"]');
        req._add("body", payload);
        
        // Send the request to the Chainlink oracle
        _sendOperatorRequest(req, fee);
    }

    function _sendMailRepayLoan(string memory _email) public {

        Chainlink.Request memory req = _buildChainlinkRequest(jobId, address(this), this.fulfill.selector); 
        string memory payload = string(abi.encodePacked('{"email":"', _email, '"}'));
        req._add("method", "POST");
        req._add("url", "https://email-service-backend-1.onrender.com/swagger-ui/index.html#/offer-controller/repayLoan");
        req._add("headers", '["content-type", "application/json"]');
        req._add("body", payload);
        
        // Send the request to the Chainlink oracle
        _sendOperatorRequest(req, fee);
    }
    




    // Callback function
    function fulfill(bytes32 _requestId, uint256 _data) public recordChainlinkFulfillment(_requestId) {
        response = _data;
    }

    // Helper function to convert uint256 to string
    function uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }



    ///////////////////////
    /// VIEW FUNCTIONS ///
    //////////////////////

    /// @dev for getting the gitcoinpoint score
    /// @param _user the address of you wan to check the score for.
    /// @return _score the user scors.
    function get_gitCoinPoint(
        address _user
    ) external view returns (uint256 _score) {
        _score = addressToUser[_user].gitCoinPoint;
    }

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

    /// @dev get the collection of all collateral token
    /// @return {address[] memory} the collection of collateral addresses
    function getAllCollateralToken() external view returns (address[] memory) {
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

    /// @dev gets all the offers for a particular user
    /// @param _borrower the user who is trying to borrow
    /// @param _requestId the id of the request you are trying to get the offers from
    /// @return {Offer[] memory} the collection of offers made
    function getAllOfferForUser(
        address _borrower,
        uint96 _requestId
    ) external view returns (Offer[] memory) {
        Request storage _foundRequest = request[_borrower][_requestId];
        return _foundRequest.offer;
    }

    /// @dev gets the amount of collateral auser has deposited
    /// @param _sender the user who has the collateral
    /// @param _tokenAddr the user who has the collateral
    /// @return {uint256} the return variables of a contract’s function state variable
    function gets_addressToCollateralDeposited(
        address _sender,
        address _tokenAddr
    ) external view returns (uint256) {
        return s_addressToCollateralDeposited[_sender][_tokenAddr];
    }

    /// @dev gets all the requests from the protocol
    /// @return {Request[] memory} all requests created
    function getAllRequest() external view returns (Request[] memory) {
        return s_requests;
    }

    function getRequestById(
        uint96 _requestId
    ) external view returns (Request memory) {
        if (_requestId == 0) revert Protocol__InvalidId();
        if (_requestId >= s_requests.length) revert Protocol__InvalidId();
        Request memory _request = s_requests[_requestId - 1];

        Request memory _requestById = request[_request.author][_requestId];
        return _requestById;
    }

    /// @dev calculates the loan interest and add it to the loam
    /// @param _returnDate the date at which the loan should be returned
    /// @param _amount the amount the user want to borrow
    /// @param _interest the percentage the user has agreed to payback
    /// @param _token the token the user want to borrow
    /// @return _totalRepayment the amount the user is to payback
    function _calculateLoanInterest(
        uint256 _returnDate,
        uint256 _amount,
        uint8 _interest,
        address _token
    ) internal view returns (uint256 _totalRepayment) {
        if (_returnDate < block.timestamp)
            revert Protocol__DateMustBeInFuture();
        // usd value
        uint256 amountInUsd = getUsdValue(_token, _amount);
        // Calculate the total repayment amount including interest
        _totalRepayment = (amountInUsd * _interest) / 100;
        return _totalRepayment;
    }

    /// @dev gets a request from a user
    /// @param _user the addresss of the user
    /// @param _requestId the id of the request that was created by the user
    /// @return Documents the return variables of a contract’s function state variable
    function getUserRequest(
        address _user,
        uint96 _requestId
    ) external view returns (Request memory) {
        return request[_user][_requestId];
    }
       // Update fees

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
        _totalBurrowInUsd = addressToUser[_user].totalLoanCollected;
        _collateralValueInUsd = getAccountCollateralValue(_user);
    }

    function getOracleAddress() public view onlyOwner returns (address) {
        return oracleAddress;
    }

    function getJobId() public view onlyOwner returns (string memory) {
        return string(abi.encodePacked(jobId));
    }

    /// @return _assets the collection of token that can be loaned in the protocol
    function getLoanableAssets()
        external
        view
        returns (address[] memory _assets)
    {
        _assets = s_loanableToken;
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
            s_isLoanable[_tokens[i]] = true;
            s_priceFeeds[_tokens[i]] = _priceFeeds[i];
            s_collateralToken.push(_tokens[i]);
        }
        s_PEER = PeerToken(_peerAddress);
         _setChainlinkToken(0xE4aB69C077896252FAFBD49EFD26B5D171A32410);
        setOracleAddress(0xa57f0cEd49bB1ed7327f950B12a8419cFD01855f);
        setJobId("a8356f48569c434eaa4ac5fcb4db5cc0");
        setFeeInHundredthsOfLink(0); 
    }

    /// @dev Assist with upgradable proxy
    /// @param {address} a parameter just like in doxygen (must be followed by parameter name)
    function _authorizeUpgrade(address) internal override onlyOwner {}

// interface Protocol {
//     function depositCollateral();
//     function redeemCollateral();
//     function createRequest();
//     function createOffer();

//     function serliquidateUserviceRequest();
//     function ();
//     function tokenCollateral();
// }
}