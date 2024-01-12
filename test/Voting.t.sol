// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Voting.sol";

contract VotingTest is Test {
    Voting voting;
    address public owner;
    address public candidator1;
    address public candidator2;
    address public candidator3;

    event RegisterVoter(address indexed voter);
    event AddCandidate(address indexed candidate);

    function setUp() public {
        owner = vm.addr(1);
        candidator1 = vm.addr(100);
        candidator2 = vm.addr(101);
        candidator3 = vm.addr(102);

        vm.prank(owner);
        voting = new Voting();
    }

    function testDeployment() public {
        assertEq(voting.isElectionStarted(), false);
    }

    function testRegisterVoter() public {
        address voter1 = vm.addr(2);
        address voter2 = vm.addr(3);
        vm.startPrank(voter1);
        vm.expectEmit();
        emit RegisterVoter(voter1);
        voting.registerVoter();
        vm.expectRevert("Already registered");
        voting.registerVoter();
        vm.stopPrank();

        vm.prank(owner);
        voting.startElection();
        vm.prank(voter1);
        vm.expectRevert("Cannot register once election started");
        voting.registerVoter();

        assertEq(voting.getVoter(voter1), "Registered");
        assertEq(voting.getVoter(voter2), "Not registered");
    }

    function testAddCandidate() public {
        address user1;
        user1 = vm.addr(2);

        vm.prank(user1);
        vm.expectRevert();
        voting.addCandidate(candidator1);

        vm.startPrank(owner);
        voting.addCandidate(candidator1);
        voting.addCandidate(candidator2);
        voting.addCandidate(candidator3);

        vm.expectRevert("Already added");
        voting.addCandidate(candidator1);
        vm.stopPrank();

        uint256 length = voting.getCandidateLength();
        assertEq(length, 3);
    }

    function testVote() public {
        address voter1 = vm.addr(2);
        address voter2 = vm.addr(3);
        address voter3 = vm.addr(4);

        vm.prank(voter1);
        voting.registerVoter();
        vm.prank(voter2);
        voting.registerVoter();

        vm.startPrank(owner);
        voting.addCandidate(candidator1);
        voting.addCandidate(candidator2);
        vm.stopPrank();

        vm.prank(voter1);
        vm.expectRevert("Election has not started");
        voting.vote(candidator1);

        vm.prank(owner);
        voting.startElection();
        vm.prank(voter1);
        vm.expectRevert("Candidate not added");
        voting.vote(candidator3);
        
        vm.startPrank(voter1);
        voting.vote(candidator1);
        vm.expectRevert("Voter is not registered or already voted");
        voting.vote(candidator2);
        vm.stopPrank();    

        assertEq(voting.getVoter(voter1), "Already voted");
        assertEq(voting.getVoter(voter2), "Registered");
        assertEq(voting.getVoter(voter3), "Not registered");
    }

    function testGetElectionResult() public {
        address voter1 = vm.addr(2);
        address voter2 = vm.addr(3);
        address voter3 = vm.addr(4);
        address voter4 = vm.addr(5);

        vm.prank(voter1);
        voting.registerVoter();
        vm.prank(voter2);
        voting.registerVoter();
        vm.prank(voter3);
        voting.registerVoter();
        vm.prank(voter4);
        voting.registerVoter();

        vm.startPrank(owner);
        voting.addCandidate(candidator1);
        voting.addCandidate(candidator2);
        voting.addCandidate(candidator3);
        voting.startElection();
        vm.stopPrank();

        vm.prank(voter1);
        voting.vote(candidator1);
        vm.prank(voter2);
        voting.vote(candidator2);
        vm.prank(voter3);
        voting.vote(candidator3);
        vm.prank(voter4);
        voting.vote(candidator2);

        assertEq(voting.getElectionResult(), candidator2);
        assertEq(voting.getCandidate(candidator1), 1);
        assertEq(voting.getCandidate(candidator2), 2);
        assertEq(voting.getCandidate(candidator3), 1);
    }

}