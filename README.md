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

### Deployment

The contracts was deployed via Foundry developement environment.

### Contract Addresses

- **$PEER Token**: `0x7820EC0281fC9c5D6584868732049D72c6dd36CC`
- **Governance Contract**: `0xA2EB92c16BB74C93933540e1164C2EbBd48411C5`
- **Proxy Contract**: `0xB0b21e5013F49Ab71e3dD39ed626A8bf9F35A130`
- **Protocol Contract**: `0xcEb3F79c2D8F8a8F427556690d211F26b4097D33`

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

