// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./PeerToken.sol";

/// @title Governance Contract for the platform
/// @author Benjamin Faruna, Jeremiah Samuel
/// @notice This contract that implements PeerLend DAO 

contract Governance is OwnableUpgradeable {

    /// @notice Event for VotingPowerAdded
    /// @dev this event is emitted for everytime the `addVotingPower` function is fired when the user's voting power is added
    event VotingPowerAdded(
        address indexed msgSender,
        address indexed contractAddress,
        uint256 indexed amount
    );

    /// @notice Event for creating of proposal
    /// @dev this event is emitted for everytime the `createProposal` function is fired when a new proposal is created.
    event CreatedProposal(
        address indexed msgSender,
        uint256 indexed proposalId,
        uint256 indexed deadline
    );

    /// @notice Event for voting
    /// @dev this event is emitted when a proposal if voted on. function is fired when a proposal is voted on.
    event Voted(
        address indexed msgSender,
        uint256 indexed id,
        uint256 indexed options
    );

    /// @notice Event for reduced voting power
    /// @dev this event is emitted whenever the `reduceVotingPower` function is fired whenever the voting power of the user is reduced
    event VotingPowerReduced(
        address indexed msgSender,
        address indexed contractAddress,
        uint256 indexed amount
    );

    /// @notice Event for Proposal Update
    /// @dev this event is emitted when the `ProposalUpdated` function is fired by whenver the status of the proposal is updated
    event ProposalUpdated(
        uint256 indexed proposalId,
        Status status,
        uint256 deadline
    );

    uint256 internal proposalId;

    enum ProposalType {
        INTEREST_RATE,
        COLLATERALIZATION
    }

/// @notice This shows the possible status of the proposals
/// @dev At every instance, a proposal has one of the status: PENDING, ACTIVE, SUCCEEDED, EXPIRED, EXECUTED, or DEFEATED which is presented in the enum
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

    // mapping(uint256 => Proposal) proposals;
    Proposal[] proposals;

    mapping(address => uint256) votingPower;
    mapping(address => mapping(uint256 => bool)) voted;

    function getTotalProposals() public view returns (uint256) {
        return proposalId;
    }

    function getAllProposals() public view returns (Proposal[] memory) {
        return proposals;
    }

    function getProposalLimit(
        uint256 start,
        uint256 limit
    ) public view returns (Proposal[] memory) {
        require(start + limit <= proposalId, "Index out of bounds");
        Proposal[] memory _proposals = new Proposal[](limit);

        for (uint256 i = 0; i < limit; i++) {
            _proposals[i] = proposals[start + i];
        }

        return _proposals;
    }

    function addVotingPower(uint256 _amount) public {
        IERC20 token = IERC20(address(this));
        require(_amount > 0, "Amount must be greater than 0");
        require(
            token.allowance(msg.sender, address(this)) >= _amount,
            "Not enough allowance"
        );
        token.transferFrom(msg.sender, address(this), _amount);
        votingPower[msg.sender] = votingPower[msg.sender] + _amount;

        emit VotingPowerAdded(msg.sender, address(this), _amount);
    }

    function reduceVotingPower(uint256 _amount) public {
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
    ) public onlyOwner {
        Proposal memory _newProposal;

        _newProposal.id = proposalId;
        _newProposal.initiator = msg.sender;
        _newProposal.options = _options;
        _newProposal.proposal = _proposal;
        _newProposal.proposalType = _type;
        _newProposal.status = Status.ACTIVE;
        _newProposal.deadline = block.timestamp + _deadline;

        _newProposal.vote_count = new uint256[](_options.length);

        // proposals[proposalId] = _newProposal;
        proposals.push(_newProposal);

        proposalId = proposalId + 1;

        emit CreatedProposal(msg.sender, proposalId, _deadline);
    }

    function getProposal(
        uint256 _id
    ) public view returns (Proposal memory proposal_) {
        require(_id < proposalId, "Proposal not found");
        proposal_ = proposals[_id];
    }

    function getVotingPower(address _voter) public view returns (uint256) {
        return votingPower[_voter];
    }

    function vote(uint256 _id, uint256 _option) public {
        // checks if contract is active
        require(proposals[_id].status == Status.ACTIVE, "Proposal is inactive"); // checks if contract is active
        require(votingPower[msg.sender] > 0, "Not enough voting power");
        require(!voted[msg.sender][_id], "Already voted");

        Proposal storage _proposal = proposals[_id];

        // TODO: function to execute DAO vote
        // TODO: mechanism to determine failure and success of proposal
        if (block.timestamp > _proposal.deadline) {
            if (_proposal.status == Status.ACTIVE) {
                _updateProposalStatus(_id, Status.EXPIRED);
            }
            revert("Proposal Expired");
        }

        require(_option < _proposal.options.length, "Option does not exist");
        uint256 _userVotePower = votingPower[msg.sender];

        voted[msg.sender][_id] = true;

        _proposal.vote_count[_option] =
            _proposal.vote_count[_option] +
            _userVotePower;

        emit Voted(msg.sender, _id, _option);
    }

    /// notice This returns the status of a proposalproposal status
    function getProposalStatus(
        uint256 _proposalId
    ) public view returns (Status) {
        Proposal memory proposal = proposals[_proposalId];
        return proposal.status;
    }

    function updateProposalStatus(
        uint256 _proposalId,
        Status _status
    ) public onlyOwner {
        _updateProposalStatus(_proposalId, _status);
    }

    function _updateProposalStatus(
        uint256 _proposalId,
        Status _status
    ) internal {
        Proposal storage _proposal = proposals[_proposalId];
        _proposal.status = _status;

        emit ProposalUpdated(_proposalId, _status, _proposal.deadline);
    }
}
