// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSigWallet {
    address[] public owners;
    uint public requiredApprovals;
    uint256 public transactionCount;
    uint256 public testValue;

    struct Transaction{
        address to;
        uint value;
        bool executed;
        uint256 approvals;
        bytes data;
    }

    mapping (address=>bool) isOwner;
    mapping(uint256 => Transaction) public transactions;
    mapping(uint256 => mapping(address => bool)) public transactionOwner;

    event SetValue(address indexed sender, uint256 value);
    event SubmitTransaction(address indexed owner, uint256 indexed transactionId, address to, uint256 value, bytes data);
    event ApproveTransaction(address indexed owner, uint256 indexed transactionId);
    event CancelTransaction(address indexed owner, uint256 indexed transactionId);
    event ExecuteTransaction(address indexed owner, uint256 indexed transactionId);

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner");
        _;
    }

    modifier transactionExists(uint256 _transactionId) {
        require(_transactionId < transactionCount, "Transaction does not exist");
        _;
    }    

    modifier notExecuted(uint256 _transactionId) {
        require(!transactions[_transactionId].executed, "Transaction already executed or cancelled");
        _;
    }

    modifier notConfirmed(uint256 _transactionId) {
        require(!checkOwnerConfirmed(_transactionId), 
            "Transaction already confirmed by this owner");
        _;
    }

    modifier hasRequiredApprovals(uint256 _transactionId) {
        require(transactions[_transactionId].approvals >= requiredApprovals, 
            "Insufficient approvals");
        _;
    }

    /**
     * @notice When making the our wallet we should provide an array of address that represent the owners of this contract
     * that have access to this wallet.
     * We should provide the minimun number of approvals of owners needed in order to execute a transaction.
     * @param _owners Array of owners addresses of the contract
     * @param _requiredApprovals the number of addresses needed to approve for a transaction in order ro execute
     */
    constructor(address[] memory _owners, uint256 _requiredApprovals) {
        require(_owners.length > 0, "Need one more owner required");
        require(_requiredApprovals > 0 && _requiredApprovals <= _owners.length, 
            "Invalid number of required approvals");

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner address");
            require(!isOwner[owner], "Duplicate owner");
            isOwner[owner] = true;
            owners.push(owner);
        }

        requiredApprovals = _requiredApprovals;
    }

    /**
     * @notice Sumbit new tx into our multisig wallet
     * Only registered as owner can submit transaction
     * @param _to address that will receive the transaction
     * @param _value the amount of ETH that will transfered to the receiver
     * @param _data data passed with the tx
     */
    function submitTransaction(
        address _to, 
        uint256 _value, 
        bytes calldata _data
    ) external onlyOwner {
        uint256 transactionId = transactionCount++;

        transactions[transactionId] = Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            approvals: 0
        });

        emit SubmitTransaction(msg.sender, transactionId, _to, _value, _data);
    }

    /**
     * @notice Approve the transaction already sumbitted, but it is waiting approvals to be executed
     * If transaction id does not exist it will revert,
     * If transaction already executed it will revert,
     * If transaction is already approved before it will revert
     * @param _transactionId transaction index in transaction array
     */
    function approveTransaction(uint256 _transactionId) 
        external 
        onlyOwner 
        transactionExists(_transactionId) 
        notExecuted(_transactionId) 
        notConfirmed(_transactionId) 
    {
        //Increase the approval for this tranaction
        transactions[_transactionId].approvals++;
        //Set this owner to true for this transaction
        transactionOwner[_transactionId][msg.sender] = true;
        emit ApproveTransaction(msg.sender, _transactionId);
    }

    /**
     * @notice execute the transaction which call 'setValue()' method
     * If non-owner call this method it will revert,
     * If transation does not exist it will revert,
     * If transaction already exeucted it will revert,
     * If transaction has no required approvals it will revert
     * @param _transactionId transaction index in transactions
     */
    function executeTransaction(uint256 _transactionId) 
        public 
        onlyOwner 
        transactionExists(_transactionId) 
        notExecuted(_transactionId) 
        hasRequiredApprovals(_transactionId) 
    {
        Transaction storage txn = transactions[_transactionId];
        txn.executed = true;
        
        (bool success, ) = txn.to.call(txn.data);
        require(success, "Transaction execution failed");

        emit ExecuteTransaction(msg.sender, _transactionId);
    }

    /**
     * @notice Cancel the transaction as set the executed state as true
     * Only owner can cancel the transaction
     * If transaction does not exist it will revert,
     * If transaction already executed it will revert
     * @param  _transactionId transaction id to cancel
     */
    function cancelTransaction(uint256 _transactionId) 
        external 
        onlyOwner 
        transactionExists(_transactionId) 
        notExecuted(_transactionId) 
    {
        transactions[_transactionId].executed = true;
        emit CancelTransaction(msg.sender, _transactionId);
    }

    /**
     * @notice Check the transaction is confirmed
     * @param _transactionId check transaction id
     */
    function isConfirmed(uint256 _transactionId) public view returns (bool) {
        return transactions[_transactionId].executed || transactions[_transactionId].approvals > 0;
    }

    /**
     * @notice Check the transaction is confirmed by this owner
     * @param _transactionId check transaction id
     */
    function checkOwnerConfirmed(uint256 _transactionId) public view returns(bool) {
        require(isOwner[msg.sender], "Not an owner");
        return transactionOwner[_transactionId][msg.sender];
    }

    /**
     * @notice Return owners array
     */
    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    /**
     * @notice Transaction count
     */
    function getTransactionCount() external view returns (uint256) {
        return transactionCount;
    }

    /**
     * @notice transaction
     * @param _transactionId transaction id
     */
    function getTransaction(uint256 _transactionId) 
        external 
        view 
        returns (address, uint256, bytes memory, bool, uint256) 
    {
        Transaction memory txn = transactions[_transactionId];
        return (txn.to, txn.value, txn.data, txn.executed, txn.approvals);
    }

    /**     
     * Set testValue method using executeTransaction
     */
    function setValue(uint256 _value) external {
        testValue = _value;
        emit SetValue(msg.sender, _value);
    }
    
}