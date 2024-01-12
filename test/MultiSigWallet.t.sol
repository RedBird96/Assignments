// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/MultiSigWallet.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet wallet;
    address public owner1;
    address public owner2;
    address public owner3;
    address public owner4;
    uint256 public requireApproval;

    event SubmitTransaction(address indexed owner, uint256 indexed transactionId, address to, uint256 value, bytes data);
    event ApproveTransaction(address indexed owner, uint256 indexed transactionId);
    event SetValue(address indexed sender, uint256 value);
    event CancelTransaction(address indexed owner, uint256 indexed transactionId);

    function setUp() public {
        owner1 = vm.addr(1);
        owner2 = vm.addr(2);
        owner3 = vm.addr(3);
        owner4 = vm.addr(4);
        requireApproval = 3;

        vm.prank(owner1);
        address[] memory ar = new address[](4);
        ar[0] = owner1;
        ar[1] = owner2;
        ar[2] = owner3;
        ar[3] = owner4;

        wallet = new MultiSigWallet(
            ar,
            requireApproval
        );
    }

    function testDeployment() public {
        assertEq(wallet.requiredApprovals(), requireApproval);
    }

    function testSubmitTransaction() public {
        address nonOwner = vm.addr(5);
        address receiver = vm.addr(6);
        uint256 amount = 0.1 ether;
        bytes memory data = new bytes(0);
        vm.prank(nonOwner);
        vm.expectRevert("Not an owner");
        wallet.submitTransaction(receiver, amount, data);

        vm.prank(owner1);
        vm.expectEmit();
        emit SubmitTransaction(owner1, 0, receiver, amount, data);
        wallet.submitTransaction(receiver, amount, data);
    }

    function testApproveTransaction() public {
        address nonOwner = vm.addr(5);
        address receiver = vm.addr(6);
        uint256 amount = 0.1 ether;
        bytes memory data = new bytes(0);
        vm.prank(owner1);
        wallet.submitTransaction(receiver, amount, data);
        
        uint256 transactionId = 0;
        vm.prank(nonOwner);
        vm.expectRevert("Not an owner");
        wallet.approveTransaction(transactionId);

        vm.expectRevert("Transaction does not exist");
        vm.prank(owner1);
        wallet.approveTransaction(transactionId + 1);
        vm.expectEmit();
        emit ApproveTransaction(owner1, transactionId);
        vm.prank(owner1);
        wallet.approveTransaction(transactionId);
        vm.prank(owner1);
        vm.expectRevert("Transaction already confirmed by this owner");
        wallet.approveTransaction(transactionId);
        vm.prank(owner2);
        vm.expectEmit();
        emit ApproveTransaction(owner2, transactionId);
        wallet.approveTransaction(transactionId);
    }

    function testExecuteTransaction(uint256 _value) public {
        address receiver = address(wallet);
        uint256 amount = 0.1 ether;
        bytes memory data = abi.encodeWithSignature("setValue(uint256)", _value);
        vm.prank(owner1);
        wallet.submitTransaction(receiver, amount, data);
        
        uint256 transactionId = 0;
        vm.prank(owner1);
        vm.expectRevert("Insufficient approvals");
        wallet.executeTransaction(transactionId);
        vm.prank(owner1);
        wallet.approveTransaction(transactionId);
        vm.prank(owner2);
        wallet.approveTransaction(transactionId);
        vm.prank(owner3);
        wallet.approveTransaction(transactionId);
        vm.prank(owner3);
        vm.expectEmit();
        emit SetValue(address(wallet), _value);
        wallet.executeTransaction(transactionId);

        vm.prank(owner2);
        vm.expectRevert("Transaction already executed or cancelled");
        wallet.executeTransaction(transactionId);
    }

    function testCancelTransaction(uint256 _value) public {
        address receiver = address(wallet);
        uint256 amount = 0.1 ether;
        bytes memory data = abi.encodeWithSignature("setValue(uint256)", _value);
        vm.prank(owner1);
        wallet.submitTransaction(receiver, amount, data);

        uint256 transactionId = 0;
        vm.prank(owner2);
        vm.expectRevert("Transaction does not exist");
        wallet.cancelTransaction(transactionId + 1);
        vm.prank(owner2);
        vm.expectEmit();
        emit CancelTransaction(owner2, transactionId);
        wallet.cancelTransaction(transactionId);

        vm.prank(owner2);
        vm.expectRevert("Transaction already executed or cancelled");
        wallet.cancelTransaction(transactionId);

    }
}