# Governance

PeerLend is a decentralized peer-to-peer protocol governed by **$Peer** holders. This governance model enables the community to propose, vote on, and implement changes within the protocol.

### **Creating Proposals**

To initiate a proposal, the Governance contract is initialized, which is restricted to `onlyOwner`. When a decision needs to be made within the protocol, a proposal is created using the `createProposal` function, requiring the following inputs:

* **`string memory _proposal`**: Description of the proposal.
* **`string[] memory _options`**: Array of options for the proposal.
* **`ProposalType _type`**: Type of proposal.
* **`uint256 _deadline`**: Deadline for voting on the proposal.

**getTotalProposals Function**

The `getTotalProposals` function keeps track of the total number of proposals within the DAO. It returns a `uint256` value representing the total count of proposals created in the protocol.

```solidity
function getTotalProposals() public view returns (uint256) {
    return proposalId;
}
```

**getAllProposals Function**

Every proposal created and voted on in the history of the protocol is stored on the Governance smart contract. The `getAllProposals` function returns an array containing details of every proposal on the protocol. Each proposal is structured according to the `Proposal` struct.

```solidity
struct Proposal {
    uint256 id;
    address initiator;
    string proposal;
    string[] options;
    uint256[] vote_count;
    ProposalType proposalType;
    Status status;
    uint256 deadline;
}

function getAllProposals() public view returns (Proposal[] memory) {
    return proposals;
}
```

### **getProposalLimit Function**

The `getProposalLimit` function, accessible to Admins and other Protocol users, facilitates quick search and filter operations. It accepts two arguments, `uint256 start` and `uint256 limit`, allowing users to search within a specified range.



### **getProposalStatus Function**

The `getProposalStatus` function provides the current status of a proposal. PeerLend Governance supports five possible proposal states: `PENDING`, `ACTIVE`, `SUCCEEDED`, `EXPIRED`, `EXECUTED`, and `DEFEATED`.

```solidity
function getProposalStatus(uint256 _proposalId) public view returns (Status) {
    Proposal memory proposal = proposals[_proposalId];
    return proposal.status;
}
```

### **Voting Power**

In a decentralized system, voting power must be balanced to ensure fairness. The concept of voting power is integrated into PeerLend Governance, ensuring that community members with higher stakes do not dominate the voting process.

To be eligible to vote, users must stake a certain amount of $Peer tokens. The `addVotingPower` function is used to stake tokens, while `reduceVotingPower` is used when a user wants to unstake.

PeerLend Governance Protocol is committed to fostering transparency, decentralization, and community participation within the lending protocol. With these governance mechanisms in place, users can actively contribute to the evolution and success of the protocol.
