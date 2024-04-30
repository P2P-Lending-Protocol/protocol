# Protocol contract

Protocol Contract

The protocol contract contains a set of logic and functions that PeerLend operates on for decentralized finance operations, including lending and borrowing, managing user assets, implementing on-chain oracles from Chainlink, and managing users. It utilizes the EIP1822 UUPS standard from the OpenZeppelin library for upgradability. The choice of this standard is due to the ease of implementation provided by UUPS.

**Dependencies and Libraries**

The contract is bootstrapped by libraries from OpenZeppelin and Chainlink's Aggregator. For token operations, the PeerToken contract is imported to enable that.

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

**Functions**

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
    // Implementation details omitted for brevity
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
    // Implementation details to be completed
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

