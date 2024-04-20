// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "./PeerToken.sol";

contract Governance {
    uint256 internal proposalId;

    enum ProposalType {
        INTEREST_RATE,
        CAP
    }

    enum Status {
        PENDING,
        ACTIVE,
        SUCCEEDED,
        EXPIRED,
        EXECUTED,
        DEFEATED
    }

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

    mapping(uint256 => Proposal) proposals;

    mapping(address => uint256) votingPower;

    function addVotingPower(uint256 _amount) public {
        // transfer user token to contract
        // IERC20.transferFrom(msg.sender, address(this), _amount);

        votingPower[msg.sender] = votingPower[msg.sender] + _amount;
    }

    function reduceVotingPower(uint256 _amount) public {
        // transfer user token to contract
        // IERC20.transferFrom(msg.sender, address(this), _amount);
        require(votingPower[msg.sender] >= _amount, "Not Enough voting power");

        votingPower[msg.sender] = votingPower[msg.sender] - _amount;
    }

    function createProposal(
        string memory _proposal,
        string[] memory _options,
        ProposalType _type,
        uint256 _deadline
    ) public {
        Proposal memory _newProposal;

        _newProposal.id = proposalId;
        _newProposal.initiator = msg.sender;
        _newProposal.options = _options;
        _newProposal.proposal = _proposal;
        _newProposal.proposalType = _type;
        _newProposal.status = Status.PENDING;
        _newProposal.deadline = block.number + _deadline;

        proposals[proposalId] = _newProposal;

        proposalId = proposalId + 1;
    }

    function getProposal(
        uint256 _id
    ) public view returns (Proposal memory proposal_) {
        proposal_ = proposals[_id];
    }

    function vote(uint256 _id, uint256 _option) public {
        require(votingPower[msg.sender] > 0, "Not enough voting power");

        Proposal storage _proposal = proposals[_id];

        require(_option < _proposal.options.length, "Option does not exist");
        uint256 _userVotePower = votingPower[msg.sender];

        _proposal.vote_count[_option] =
            _proposal.vote_count[_option] +
            _userVotePower;

        // emit event
    }
}
