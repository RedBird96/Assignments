// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable {
    using SafeERC20 for IERC20;

    struct CandidateInfo {
        bool isAdded;
        uint256 voteCount;
    }

    enum VotingInfo {
        NON_REGISTERED,
        REGISTERED,
        VOTED
    }

    mapping(address => CandidateInfo) candidate;
    mapping(address => VotingInfo) voter;
    address[] public candidateArray;
    bool public isElectionStarted;

    event RegisterVoter(address indexed voter);
    event AddCandidate(address indexed candidate);
    event Vote(address indexed voter, address indexed candidate);

    constructor() Ownable (msg.sender) {
        isElectionStarted = false;
    }

    /**
     * @notice Register vote on this system.
     * If the election not started or the voter already registered it will reverted.
     * Only non-registered voter can register
     */
    function registerVoter() external {
        require(isElectionStarted == false, "Cannot register once election started");
        require(voter[msg.sender] == VotingInfo.NON_REGISTERED, "Already registered");
        voter[msg.sender] = VotingInfo.REGISTERED;
        emit RegisterVoter(msg.sender);
    }

    /**
     * @notice Start the election
     */
    function startElection() external onlyOwner {
        isElectionStarted = true;
    }

    /**
     * @notice Add candidate on this system.
     * Candidate can add only once.
     * @param _candidateAddress Candidate address for adding
     */
    function addCandidate(address _candidateAddress) external onlyOwner {
        require(isElectionStarted == false, "Cannot add once election started");
        require(candidate[_candidateAddress].isAdded == false, "Already added");
        //Create candidate info for this new candidate address
        candidate[_candidateAddress] = CandidateInfo({
            isAdded: true,
            voteCount: 0
        });
        candidateArray.push(_candidateAddress);
        emit AddCandidate(_candidateAddress);
    }

    /**
     * @notice Vote candidate for msg.sender vote
     * Check if msg.sender registered as voter and will revert if not registered.
     * Also voter can only vote only once.
     * @param _candidateAddress Candidate address for voting
     */
    function vote(address _candidateAddress) external {
        require(isElectionStarted == true, "Election has not started");
        require(voter[msg.sender] == VotingInfo.REGISTERED, 
            "Voter is not registered or already voted");
        require(candidate[_candidateAddress].isAdded, "Candidate not added");
        //Increase votecount for this candidate
        candidate[_candidateAddress].voteCount ++;
        //Set this vote status as VOTED
        voter[msg.sender] = VotingInfo.VOTED;
        emit Vote(msg.sender, _candidateAddress);
    }

    /**
     * @notice Return winner candidate address
     * Select the winner which has biggest voteCount.
     * If there are same voteCount, return first selected candidate
     */
    function getElectionResult() external view returns(address winner) {
        uint256 length = candidateArray.length;
        require(length != 0, "No candidate");

        winner = candidateArray[0];
        uint256 index;
        //Set to winner with highest vote count of candidate
        for(index = 1; index < length;) {
            address addr = candidateArray[index];
            if (candidate[winner].voteCount < candidate[addr].voteCount)
                winner = addr;
            unchecked {
                index++;
            }
        }
        return winner;
    }

    /**
     * @notice Return candidate vote Count
     * @param _candidateAddress Candidate address to read vote count
     */
    function getCandidate(address _candidateAddress) external view returns(uint256) {
        require(candidate[_candidateAddress].isAdded, "Candidated not added");
        return candidate[_candidateAddress].voteCount;
    }

    /**
     * @notice Return voter status if it's registered or voted
     * @param _voterAddress vote address
     */
    function getVoter(address _voterAddress) external view returns(string memory) {
        if (voter[_voterAddress] == VotingInfo.NON_REGISTERED)
            return "Not registered";
        if (voter[_voterAddress] == VotingInfo.VOTED)
            return "Already voted";
        else
            return "Registered";
    }

    /**
     * @notice Return candidate array length
     */
    function getCandidateLength() external view returns(uint256) {
        return candidateArray.length;
    }
    
}