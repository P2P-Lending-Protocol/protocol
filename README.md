## PeerLend Protocol

PeerLend Protocol is a decentralized lending protocol implemented on the Ethereum blockchain. It allows users to borrow and lend digital assets in a peer-to-peer manner without the need for intermediaries.

### Overview

The PeerLend Protocol consists of several smart contracts deployed on the Ethereum blockchain. Below is an overview of each contract:

#### Governance.sol

- **Description**: This contract handles the governance aspects of the PeerLend platform, including proposal creation, voting, and delegation of voting power.
- **Key Features**:
  - Creation and management of governance proposals.
  - Staking of tokens for voting power.
  - Delegation of voting power to other addresses.

#### PeerToken.sol

- **Description**: This contract implements the ERC20 standard for a utility token called PEER. PEER tokens are used within the PeerLend ecosystem for various purposes, including staking for voting power and as collateral for loans.
- **Key Features**:
  - Minting new tokens by the contract owner.
  - Transferring tokens between addresses.

#### Protocol.sol

- **Description**: The main contract of the PeerLend Protocol responsible for facilitating lending operations, including depositing collateral, creating loan requests, making lending offers, and servicing requests.
- **Key Features**:
  - Deposit and withdraw collateral.
  - Create and manage loan requests.
  - Make and respond to lending offers.
  - Service loan requests by transferring funds to borrowers.
  - Health factor monitoring to ensure sufficient collateralization.

#### Libraries and Interfaces

- **Errors.sol**: Contains custom error messages used throughout the contracts.
- **Constant.sol**: Holds constant values used across the contracts.
- **Events.sol**: Defines events emitted by the contracts.
- **AggregatorV3Interface.sol**: Interface for Chainlink's price feed contracts used to obtain token prices.

### Getting Started

To deploy and interact with the PeerLend Protocol contracts, you need the following:

- Foundry 
- Ethereum Wallet.
- Solidity Language
- Chainlink Price Feed Oracle

### Deployment

The contracts was deployed via Foundry developement environment.

### Contract Addresses

- **$PEER Token**: `0x8Bbf71bC1EF43F72b5e456a59d5c817e096Bc8A4`
- **Governance Contract**: `0x57014287f2DA0b1494502849A0F6C3b628cdADC4`
- **Proxy Contract**: `0x9b76e44C8d3a625D0d5e9a04227dc878B31897C2`
- **Protocol Contract**: `0xb0dbA4BDEC9334f4E9663e9b9941E37018BbE81a`

### Project Live Page

You can interact with the live project throught this link https://peer-lend-dapp.vercel.app/


### Usage

To interact with the PeerLend platform, you can follow these steps:

#### Build

```bash
$ forge build
```

#### Test

```bash
$ forge test
```

#### Format

```bash
$ forge fmt
```

#### Gas Snapshots

```bash
$ forge snapshot
```


### Contributing

Contributions to the PeerLend Protocol project are welcome! Please follow the guidelines outlined in the CONTRIBUTING.md file.

### License

The PeerLend Protocol contracts are licensed under the MIT License. See the LICENSE file for details.

