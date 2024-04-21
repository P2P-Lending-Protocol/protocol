// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./PeerToken.sol";

contract Governance {
    
    event VotingPowerAdded(address indexed msg.sender, address indexed contractAddress, uint256 indexed amount);
    event CreatedProposal(address indexed msg.sender, uint256 indexed proposalId, uint256 indexed deadline);
    event Voted(address indexed msg.sender, uint256 indexed id, string indexed options);
    event VotingPowerReduced(address indexed msg.sender, address indexed contractAddress, uint256 indexed amount);
    event GetProposal(uint256 indexed id);



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
    mapping(address => uint256) votingRewards;
    mapping(address => mapping(uint256 => bool)) voted;

    function addVotingPower(uint256 _amount) public {
        IERC20 token = IERC20(address(this));
        require(_amount > 0, "Amount must be greater than 0");
        require(
            token.allowance(msg.sender, address(this)) >= _amount,
            "Not enough allowance"
        );
        token.transferFrom(msg.sender, address(this), _amount);
        votingPower[msg.sender] = votingPower[msg.sender] + _amount;

        // emit event
        emit VotingPowerAdded(msg.sender, address(this), _amount);
    }

    function reduceVotingPower(uint256 _amount) public {
        // transfer user token to contract
        require(votingPower[msg.sender] >= _amount, "Not Enough voting power");
        IERC20 token = IERC20(address(this));

        votingPower[msg.sender] = votingPower[msg.sender] - _amount;
        token.transfer(msg.sender, _amount);

        emit VotingPowerReduced(msg.sender, address(this), _amount);

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

        _newProposal.vote_count = new uint256[](_options.length);

        proposals[proposalId] = _newProposal;

        proposalId = proposalId + 1;

        emit CreatedProposal(msg.sender, proposalId, _deadline);

    }

    function getProposal(
        uint256 _id
    ) public view returns (Proposal memory proposal_) {
        proposal_ = proposals[_id];

        emit GetProposal(_id);
    }

    function vote(uint256 _id, uint256 _option) public {
       // checks if contract is active
        require(proposal[_id].status == Status.ACTIVE, "Proposal is inactive");    // checks if contract is active
        require(votingPower[msg.sender] > 0, "Not enough voting power");
        require(!voted[msg.sender][_id], "Already voted");

        Proposal storage _proposal = proposals[_id];

        require(_option < _proposal.options.length, "Option does not exist");
        uint256 _userVotePower = votingPower[msg.sender];

        voted[msg.sender][_id] = true;

        _proposal.vote_count[_option] =
            _proposal.vote_count[_option] +
            _userVotePower;
        

        // issue voting rewards

      // emit event
      emit Voted(msg.sender, _id, _option);

        }
      

       /* notice proposal status
    * this indicates the status of the proposal if ACTIVE, PENDING, COMPLETED...
    *
    */

    function getProposalStatus(uint256 id) public returns(Status){
        require(_proposalId <= proposalId, "Invalid proposal Id");
        Proposal storage proposal = proposals[_proposalId];
        return proposal.status;
        emit GetProposal( id);
    }

    }


