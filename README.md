# PeerLend Protocol

PeerLend is a lending protocol built on blockchain technology allowing users to borrow and lend digital assets without the need for intermediaries like banks or financial institutions.


## Key Features

**1. Decentralization**

PeerLend operates on a decentralized network, meaning there is no central authority controlling the lending process. Instead, it relies on smart contracts deployed on the Ethereum blockchain to facilitate lending transactions. This decentralization ensures transparency, security, and fairness in the lending process.

**2. Peer-to-Peer Transactions**

The platform facilitates direct lending transactions between lenders and borrowers. Borrowers can request loans, and lenders can offer loans directly to them. This peer-to-peer model eliminates the need for intermediaries, reducing transaction costs and streamlining the lending process.

**3. Security and Trust**
PeerLend leverages blockchain technology to enhance security and trust in lending transactions. Smart contracts govern the lending process, ensuring that funds are securely transferred between parties according to predefined terms and conditions. Additionally, the use of blockchain provides an immutable record of all lending activities, enhancing transparency and accountability.

**4. Flexible Loan Terms**

Users have the flexibility to define their loan terms, including loan amount, interest rate, and repayment period. Borrowers can choose from a variety of loan offers provided by lenders, allowing them to select the most favorable terms for their needs. This flexibility promotes competition among lenders, leading to better loan terms for borrowers.

**5. Governance by DAO**

PeerLend is governed by a Decentralized Autonomous Organization (DAO), where platform users collectively make decisions regarding the protocol's operation and development. DAO members vote on proposals related to platform upgrades, changes in protocol parameters, and governance policies, ensuring that the platform evolves in a decentralized and community-driven manner.

## User Flow

**1. A lender Creates a Loan Offer**
This is the first step that initializes the cycle of operation on the lending protocol. A willing lender creates a request that loans are available to be paid according to some given conditions specified by the lender at the time of creating the request. This request is broadcasted to the PeerLend platform, where it is visible to potential borrowers.

**2. Borrower Requests Loan** 
An interested borrower specifies the desired interest rate and repayment terms. This request is broadcasted to the PeerLend platform, where it is visible to the lender.

**3. Lenders Offer Loans**
Lenders review the loan requests posted by borrowers and decide whether to offer loans. Lenders specify their loan terms, including the interest rate and repayment period, when making loan offers.

**4. Borrower Accepts Loan Offer**
Once borrowers receive loan offers from lenders, they evaluate the terms and select the most suitable offer. Upon acceptance, the loan terms are finalized, and the smart contract automatically executes the loan agreement, transferring the loan amount to the borrower's wallet.

**5. Repayment and Rewards**
Borrowers repay their loans according to the agreed-upon terms, including interest payments. As borrowers repay their loans, lenders receive principal and interest payments directly to their wallets. Additionally, borrowers maintain a good credit score for timely loan repayment.

## Benefits of PeerLend

**Accessibility:** PeerLend provides access to loans for individuals and businesses who may have limited by traditional financial services.
**Lower Costs:** By eliminating intermediaries, PeerLend reduces transaction costs associated with lending, benefiting both borrowers and lenders.
**Transparency:** The use of blockchain technology ensures transparency and immutability of lending transactions, enhancing trust among platform users.
**Flexibility:** Users have the flexibility to define their own loan terms, enabling customized borrowing and lending experiences.
**Community Governance:** The decentralized governance model allows platform users to participate in decision-making, ensuring that the platform evolves according to the community's needs and preferences.

## Project Live Page

You can interact with the live project throught this [link](https://peer-lend-dapp.vercel.app/)
![alt text](<dashboard.png>)

## Overview Of Protocol 

The PeerLend Protocol consists of several smart contracts deployed on the Ethereum blockchain. Below is an overview of each contract:

### Governance.sol

- **Description**: This contract handles the governance aspects of the PeerLend platform, including proposal creation, voting, and delegation of voting power.
- **Key Features**:
  - Creation and management of governance proposals.
  - Staking of tokens for voting power.
  - Delegation of voting power to other addresses.

### PeerToken.sol

- **Description**: This contract implements the ERC20 standard for a utility token called PEER. PEER tokens are used within the PeerLend ecosystem for various purposes, including staking for voting power and as collateral for loans.
- **Key Features**:
  - Minting new tokens by the contract owner.
  - Transferring tokens between addresses.

### Protocol.sol

- **Description**: The main contract of the PeerLend Protocol responsible for facilitating lending operations, including depositing collateral, creating loan requests, making lending offers, and servicing requests.
- **Key Features**:
  - Deposit and withdraw collateral.
  - Create and manage loan requests.
  - Make and respond to lending offers.
  - Service loan requests by transferring funds to borrowers.
  - Health factor monitoring to ensure sufficient collateralization.

### Libraries and Interfaces

- **Errors.sol**: Contains custom error messages used throughout the contracts.
- **Constant.sol**: Holds constant values used across the contracts.
- **Events.sol**: Defines events emitted by the contracts.
- **AggregatorV3Interface.sol**: Interface for Chainlink's price feed contracts used to obtain token prices.


## Deployment

The contracts was deployed via Foundry developement environment. To deploy and interact with the PeerLend Protocol contracts, you need the following:

- Foundry 
- Ethereum Wallet.
- Solidity Language

## Contract Addresses

- **$PEER Token**: `0x7820EC0281fC9c5D6584868732049D72c6dd36CC`
- **Governance Contract**: `0xA2EB92c16BB74C93933540e1164C2EbBd48411C5`
- **Proxy Contract**: `0xB0b21e5013F49Ab71e3dD39ed626A8bf9F35A130`
- **Protocol Contract**: `0xcEb3F79c2D8F8a8F427556690d211F26b4097D33`

### Email Service Point
To enable users to have multiple login options, Peer Lend allows for email logins and receiving push notifications for transactions happening on chain. The email service point is found [here](https://email-service-backend-2.onrender.com/swagger-ui/index.html#/)


## Contributing

Contributions to the PeerLend Protocol project are welcome! Please follow the guidelines outlined in the [CONTRIBUTING.md file](https://github.com/P2P-Lending-Protocol/protocol/blob/main/contributing-guide.md).

## License

The PeerLend Protocol contracts are licensed under the MIT License. See the LICENSE file for details.

## Links
Project Documentation: [link](https://p2p-lending-protocol.gitbook.io/peer-lend/)

