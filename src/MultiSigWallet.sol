// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

// Errors
error TransactionAlreadyConfirmed();

contract MultiSig {
    address public deployer; // Sets contract deployer
    address[] public signers; // Array of multi-signers
    uint256 public requiredSigners;
    uint256 public transactionCount;

    // Tracks the signers added
    mapping(address => bool) public isSigner; // Checks if address is a signer

    // Tracks which signer approved which transaction
    mapping(uint256 => mapping(address => bool)) public isConfirmed; // TrancactionId --> Signers Addr --> Check

    // Transaction Definition
    struct Transaction {
        uint256 transactionId;
        address recipient;
        uint256 amount;
        bool isExecuted;
        uint256 numConfirmation; // Number of signers that have confirmed this transaction
    }

    // Transactions array
    Transaction[] public transactionArray;

    constructor(address[] memory _signers, uint256 _requiredSigners) {
        require(_requiredSigners > 0, "Signers required");
        require(
            _requiredSigners <= _signers.length,
            "Required signers should me less than total signers"
        );

        // set deployer
        deployer = msg.sender;
        // Add deployer as first signer
        signers.push(deployer);
        isSigner[deployer] = true;
        // Set required signers
        requiredSigners = _requiredSigners;
        // Add other signers
        for (uint i; i < _signers.length; i++) {
            require(
                _signers[i] != address(0),
                "Signer address can not be zero"
            );
            require(!isSigner[_signers[i]], "Signer already added");
            signers.push(_signers[i]);
            isSigner[_signers[i]] = true;
        }
    }

    // Deposit Ether into the smart contract
    function deposit() external payable {
        require(msg.sender != address(0), "Invalid address");
        require(msg.value > 0, "Invalid amount input");
        require(isSigner[msg.sender], "Not a signer");
    }

    function submitTransaction(address _recipient, uint256 _amount) external {
        require(msg.sender != address(0), "Invalid address");
        require(isSigner[msg.sender], "Not a signer");
        require(_amount > 0, "Invalid amount input");

        transactionCount = transactionCount + 1;
        Transaction memory transaction = Transaction({
            transactionId: transactionCount,
            recipient: _recipient,
            amount: _amount,
            isExecuted: false,
            numConfirmation: 0
        });

        transactionArray.push(transaction);
    }

    function confirmTransaction(uint256 _transactionId) external {
        uint256 transactionIndex = _transactionId - 1;

        require(isSigner[msg.sender], "Not an approved signer");
        require(msg.sender != address(0), "Invalid address");
        require(
            _transactionId <= transactionArray.length,
            "Invalid transaction Id"
        );
        require(
            !transactionArray[transactionIndex].isExecuted,
            "Transaction already executed"
        );
        require(
            !isConfirmed[transactionIndex][msg.sender],
            "Transaction already confirmed"
        );

        Transaction storage transaction = transactionArray[transactionIndex];
        transaction.numConfirmation += 1;
        isConfirmed[transactionIndex][msg.sender] = true;
    }

    function executeTransaction(uint256 _transactionId) external {
        uint256 transactionIndex = _transactionId - 1;

        require(isSigner[msg.sender], "Not an approved signer");
        require(msg.sender != address(0), "Invalid address");
        require(
            _transactionId <= transactionArray.length,
            "Invalid transaction Id"
        );
        require(
            !transactionArray[transactionIndex].isExecuted,
            "Transaction already executed"
        );

        // Get the transaction from storage
        Transaction storage transaction = transactionArray[transactionIndex];

        // Check if NumConfirmation is equal or greater than required signers
        require(
            transactionArray[transactionIndex].numConfirmation >=
                requiredSigners,
            "Transaction not confirmed"
        );

        require(
            address(this).balance > transactionArray[transactionIndex].amount,
            "Insufficient balance"
        );

        (bool success, ) = transaction.recipient.call{
            value: transaction.amount
        }("");
        require(success, "Transaction failed");
        // isExecute turns to true
        // callFn() used to send ether
    }

    function getSignersLength() public view returns (uint) {
        return signers.length;
    }
}

// ["0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2", "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db", "0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB", "0x617F2E2fD72FD9D5503197092aC168c91465E7f2"]
