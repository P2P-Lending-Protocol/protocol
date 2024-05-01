# Peer Token

PeerToken is the native asset of the protocol, which can be minted and burned upon the supply and withdrawal of assets. It follows the ERC20 token standard and is ownable by the address that is passed when deploying the contract.

The token contract includes two functions:

#### Constructor

The constructor initializes the contract with the `initialOwner` address and configures the ERC20 token with the name "PEER Token" and the symbol "PEER".

```solidity
constructor(
    address initialOwner
) ERC20("PEER Token", "PEER") Ownable(initialOwner) {}
```

#### Mint

This privileged function can only be called by `onlyOwner`. It handles the minting operations of PeerToken to specified addresses by calling the `mint` function of the OpenZeppelin ERC20 contract. It takes two parameters:

* `to`: Specifies the address to which the tokens would be minted.
* `amount`: Specifies the amount of tokens to be sent to the address.

```solidity
function mint(address to, uint256 amount) public onlyOwner {
    _mint(to, amount);
}
```

