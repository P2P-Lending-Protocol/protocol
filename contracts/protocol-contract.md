# Protocol contract

**Protocol Contract**

The protocol contract contains a set of logic and functions that PeerLend operates on for decentralized finance operations, including lending and borrowing, managing user assets, implementing on-chain oracles from Chainlink, and managing users. It utilizes the EIP1822 UUPS standard from the OpenZeppelin library for upgradability. The choice of this standard is due to the ease of implementation provided by the standard and easy maintenance.

**Dependencies and Libraries**

The contract is bootstrapped with libraries from OpenZeppelin and Chainlink's Aggregator. For token operations, the PeerToken contract is imported to enable that.

```solidity
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PeerToken} from "./PeerToken.sol";
import "./Libraries/Constant.sol";
import "./Libraries/Errors.sol";
```

**Libraries:**

* `Constant.sol`: Contains abstracted constants used in the protocol contract.

```solidity
library Constants {
    uint256 constant NEW_PRECISION = 1e10;
    uint256 constant PRECISION = 1e18;
    uint256 constant LIQUIDATION_THRESHOLD = 85;
    uint256 constant MIN_HEALTH_FACTOR = 1;
}
```

* `Errors.sol`: Contains abstracted custom errors used in the protocol contract.

```solidity
error Protocol__MustBeMoreThanZero();
error Protocol__tokensAndPriceFeedsArrayMustBeSameLength();
error Protocol__TokenNotAllowed();
error Protocol__TransferFailed();
error Protocol__BreaksHealthFactor();

error Governance__NotEnoughTokenBalance();
error Governance__NotEnoughAllowance();

error Governance__ProposalDoesNotExist();
error Governance__ProposalInactive();
error Governance__ProposalExpired();
error Governance__NotEnoughVotingPower();
error Governance__AlreadyVoted();
error Governance__AlreadyStaked();
error Governance__NoStakedToken();
error Governance__OptionDoesNotExist();
```

**State Variables Specifications**

* `s_PEER`: This is the instance of the PeerToken contract on the protocol contract.
* `s_priceFeeds`: This represents the live price value of the collateral tokens on the protocol.
* `s_addressToCollateralDeposited`: This variable holds the balance of the user's collateral assets.
* `addressToUser`: This holds the address of the user in the struct.
* `s_collateralToken`: This variable holds an array of the collateral token addresses used on the platform.

```solidity
// State Variables
PeerToken private s_PEER;
mapping(address => address) private s_priceFeeds;
mapping(address => mapping(address => uint256)) private s_addressToCollateralDeposited;
mapping(address => User) private addressToUser;
address[] private s_collateralToken;
```

**Events**

* `CollateralDeposited`: This event is emitted when a user deposits collateral, indicating the sender's address, the token deposited, and the deposited value.

```solidity
// Events
event CollateralDeposited(address indexed _sender, address indexed _token, uint256 _value);
```

* Status: This is an enum  holding the possible states of both `creatLoanRequest`, `makeOffer` and `serviceRequest` functions. The possible states are OPEN, SERVICED and CLOSED.

* OfferStatus: This is checks the status of an Offer if it is OPEN, REJECTED or ACCEPTED.

* User: 
When a new user is created on the platform there are data that are required of that user. These are contained in the User struct declared below.

```solidity
struct User {
        string email;
        address userAddr;
        bool isVerified;
        uint gitCoinPoint;
    }
```

* Request:
This is a struct outlining the different data types needed to create a request on the platform. 

* Offer:
The `Offer` is another data struct outlining the layout of data and their data types required in creating an offer request. The Offer request is in response to a loan request that has been created and broadcasted to the user's dashboard. 

```solidity
 struct Offer {
        uint256 offerId;
        address tokenAddr;
        address author;
        uint256 amount;
        uint8 interest;
        uint256 returnDate;
        OfferStatus offerStatus;
    }
```

**Functions**

### Modifiers

* `moreThanZero`: This modifier takes in a param `uint256 _amount` and implements a check on the function it is called in. Its basic operation is to check if the condition of `_amount` is less than Zero then reverts with  `Protocol__MustBeMoreThanZero()` error.

* `isTokenAllowed`: This modifier is also performs a check but limited to confirming if the token address `_token` is listed among the allowed tokens on the platform. It reverts with  Protocol__TokenNotAllowed() error is `address(0)`

#### Deposit Collateral

This function implements the logic of depositing collateral when a user needs assets to perform certain operations or borrow from others. It takes two parameters:

* `_tokenCollateralAddress`: This is the contract address of the token the user is depositing as collateral.
* `_amountOfCollateral`: This is the value of collateral the user is interested in depositing.

```solidity
function depositCollateral(address _tokenCollateralAddress, uint256 _amountOfCollateral)
    external
    moreThanZero(_amountOfCollateral)
    isTokenAllowed(_tokenCollateralAddress)
{
    // Implementation logic
}
```

### Create Lending Request

Creating a Lending request is executed by the `createLendingRequest` function to create a loan request. This takes in five params: 
   * `address _collateralAddr`: The address of the token used as collateral
   * `uint256 _amount`: The principal amount of the loan
   * `uint8 _interest`: The annual interest rate of the loan (in percentage points)
   * `uint256 _returnDate`: The unix timestamp when the loan should be repaid
   * `address _loanCurrency`: The currency in which the loan is denominated


### Calculate Loan Interest

This quickly estimates the total repayment when a loan of `uint256 _amount` is issued within a specific timeframe of `uint256 _returnDate`to another user at rate `_uint8 _interest`. 


### Make Offer to A Lending Request
Take for instance there is a lending request with an interest rate that isn't appealing, a user can simply respond to it negotitiating a prefered interest rate. The `makeLendingOffer` function makes that possible. 

```solidity

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
        // implementation logic cut short        
        }

```

### Get All Offer

To get all offers tied to a specific user in this case the borrower, the `getAllOfferForUser` function is implemented to aloow a user see all the offers on its account.

```solidity

 function getAllOfferForUser(address _borrower, uint96 _requestId) external view returns (Offer [] memory){
            Request storage _foundRequest =  request[_borrower][_requestId];
            return _foundRequest.offer;
    }
 ```   

 ### Make Lending Offer
 With the `makeLendingOffer` function, a `_borrower` can simply respond to a Loan request if the `_interest` (interest rate) or `_returnDate`in the request is not suitable with a new proposal for the owner author of the loan request either accept or decline the offer. 

```solidity
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
        if(_foundRequest.loanRequestAddr != _tokenAddress) revert Protocol__InvalidToken();

        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);
        
        amountUserIsLending[msg.sender] = _amount;

        // other code implementation cut for brevity

```

### Responding to Offer (Accepting or Rejecting)
Every request has a final state which is either ACEEPTED or REJECTED. Accepting an offer is achieved by passing `uint96 _requestId`, `uint256 _offerId`, and `o  OfferStatus _status` as params into the `respondToLendingOffer` function

```solidity
// truncated code
if (_status == OfferStatus.ACCEPTED) {
        handleAcceptedOffer(_foundRequest, _foundOffer, _offerId);
    } else if (_status == OfferStatus.REJECTED) {
        handleRejectedOffer(_foundOffer);
    }

```

### Handling Accepted Offer

This is an internal function responsible for handling an accepted offer . It transfers the lent amount from the lender to the `_borrower`, updates the status of the corresponding request to SERVICED, and refunds any remaining offers to their authors.


### Handling Rejected Offer
When an offer is rejected, the `handleRejectedOffer` function refunds the lent amount back to the offer author.

```solidity
  function handleRejectedOffer(Offer storage _foundOffer) internal {
        uint256 amountToRefund = amountUserIsLending[_foundOffer.author];
        amountUserIsLending[_foundOffer.author] = 0;
        IERC20(_foundOffer.tokenAddr).transfer(
            _foundOffer.author,
            amountToRefund
        );
    }

```

### Servicing Request

This  allows a lender to service a specific request this it does by transfering the requested amount from the lender to the `_borrower`, updates the status of the request to SERVICED, and emits an event.


#### Health Factor

The health factor is a risk management feature that shows if a user has enough collateral deposited. It calculates the health factor by comparing the total borrowed amount and collateral value.

```solidity
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
```

#### Revert If Health Factor Is Broken

This internal function checks the health factor of a user intending to mint. It reverts when the health factor is broken (less than 1).

```solidity
function _revertIfHealthFactorIsBroken(address _user) internal view {
    uint256 _userHealthFactor = _healthFactor(_user);
        if (_userHealthFactor < Constants.MIN_HEALTH_FACTOR) {
            revert Protocol__BreaksHealthFactor();
        }
}
```

#### Get Account Collateral Value

This view function returns the collateral value of a token and the amount of the address passed as the function parameter.

```solidity
function getAccountCollateralValue(address _user) public view returns (uint256 _totalCollateralValueInUsd) {
    // Implementation logic
}
```

#### Live USD Value

To get the current USD value for operations, the Chainlink AggregatorV3Interface is used to return the price feed into the protocol.

```solidity
function getUsdValue(address _token, uint256 _amount) public view returns (uint256) {
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
```

#### Account Info

This internal function returns the state of the user's account by taking only the address of the user as param

```solidity
function _getAccountInfo(address _user)
    private
    view
    returns (uint256 _totalBurrowInUsd, uint256 _collateralValueInUsd)
{
    // Implementation details cut for brevity
}
```

#### Initialize the Protocol

The protocol is initialized using this function, requiring the address of the `_initialOwner`, addresses of `_tokens`, `_priceFeeds`, and `_peerAddress`.

```solidity
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
```

#### Authorize Upgrade

This function facilitates upgradability of the contract.

```solidity
function _authorizeUpgrade(address) internal override onlyOwner {}
```

