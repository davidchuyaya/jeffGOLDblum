pragma solidity ^0.4.0;

// TODO: figure out how to make private
contract Vote {
    mapping(address => bool) private voted;

    function Vote() public {}

    function getVoted(address creditor) public view returns (bool) {
        return voted[creditor];
    }

    function setVoted(address creditor, bool _voted) public {
        voted[creditor] = _voted;
    }
}


contract JeffGOLDblum {
    // represents a member of the group of lenders
    struct Creditor {
        uint balance;
        uint index;
    }

    // represents a party that requests and receives a loan
    struct Debtor {
        uint loanAmount;
        uint balance;
        uint interest;
        uint outstandingLoanAmount;
        uint outstandingInterestAmount;
        uint index;
    }

    // represents a party that requests and receives a loan
    struct Requestor {
        uint votesYea;
        uint votesNay;
        uint requestAmount;
        uint index;
        Vote whoVoted;
    }

    event LoanRequest (address requestor, uint amount);

    address[] public creditorAddrs;
    address[] public debtorAddrs;
    address[] public requestorAddrs;

    mapping(address => Creditor) private creditors;
    mapping(address => Debtor) private debtors;
    mapping(address => Requestor) private requestors;

    uint public amountLent;

    function JeffGOLDblum() public {
        creditorAddrs = new address[](0);
        debtorAddrs = new address[](0);
        requestorAddrs = new address[](0);
        amountLent = 0;
    }

    function isCreditor(address creditor) public view returns (bool) {
        return creditorAddrs[creditors[creditor].index] == creditor;
    }

    function deposit() public payable {
        if (msg.value == 0) {
            return;
        }
        if (creditors[msg.sender].balance == 0) {
            addCreditor(msg.sender);
        }
        creditors[msg.sender].balance += msg.value;
    }

    function withdraw(uint amount) public returns (bool) {
        if (creditors[msg.sender].balance >= amount) {
            if (msg.sender.send(amount)) {
                creditors[msg.sender].balance -= amount;
                if (creditors[msg.sender].balance == 0) {
                    removeCreditor(msg.sender);
                }
                return true;
            }
        }
        return false;
    }

    // TODO
    // returns true if the loan request was submitted successfully
    function requestLoan(uint amount) public returns (bool) {
        if (debtors[msg.sender].outstandingLoanAmount > 0) {
            return false;
        }

        requestors[msg.sender].requestAmount = amount;
        requestors[msg.sender].whoVoted = new Vote();
        addRequestor(msg.sender);
        LoanRequest(msg.sender, amount);

        return true;
    }

    // vote allows a creditor to vote in favor or against a proposed loan
    // returns true if the vote was successful and false otherwise
    function vote(address requestor, bool voteYea) public returns (bool) {
        if (!isCreditor(msg.sender)) {
            return false;
        }
        if (requestors[requestor].whoVoted.getVoted(msg.sender)) {
            return false;
        }

        if (voteYea) {
            requestors[requestor].votesYea++;
        } else {
            requestors[requestor].votesNay++;
        }
        requestors[requestor].whoVoted.setVoted(msg.sender, true);

        // accept or reject the loan
        if (requestors[requestor].votesYea >= creditorAddrs.length / 2) {
            resetRequestor(requestor);
            if (requestors[requestor].requestAmount > this.balance) {
                return false;
            }
            amountLent += requestors[requestor].requestAmount;
            debtors[msg.sender].loanAmount += requestors[requestor].requestAmount;
            debtors[msg.sender].balance += requestors[requestor].requestAmount;
            debtors[msg.sender].interest += requestors[requestor].requestAmount / 100;
            debtors[msg.sender].outstandingLoanAmount +=
            requestors[requestor].requestAmount + debtors[msg.sender].interest;
            addDebtor(msg.sender);
        } else if (requestors[requestor].votesNay >= creditorAddrs.length / 2) {
            resetRequestor(requestor);
        }

        return true;
    }

    function sendFunds(uint amount, address target) public returns (bool) {
        if (amount > debtors[msg.sender].balance) {
            return false;
        }

        if (target.send(amount)) {
            debtors[msg.sender].balance -= amount;
            return true;
        }
        return false;
    }

    function makePayment() public payable returns (bool) {
        uint subtractAmount = msg.value;
        if (msg.value > debtors[msg.sender].outstandingLoanAmount) {
            subtractAmount = debtors[msg.sender].outstandingLoanAmount;
        }
        debtors[msg.sender].outstandingLoanAmount -= subtractAmount;

        if (debtors[msg.sender].outstandingLoanAmount == 0) {
            resetDebtor(msg.sender);
            removeDebtor(msg.sender);
        }

        for (uint i = 0; i < creditorAddrs.length; i++) {
            bool sent = creditorAddrs[i].send(msg.value / creditorAddrs.length);
            if (!sent) {
                return false;
            }
        }
        return true;
    }

    function addCreditor(address creditor) private {
        creditorAddrs.push(creditor);
        creditors[creditor].index = creditorAddrs.length - 1;
    }

    function removeCreditor(address creditor) private {
        address lastCreditor = creditorAddrs[creditorAddrs.length - 1];
        creditorAddrs[creditors[creditor].index] = lastCreditor;
        delete creditorAddrs[creditorAddrs.length - 1];
    }

    function addDebtor(address debtor) private {
        debtorAddrs.push(debtor);
        debtors[debtor].index = debtorAddrs.length - 1;
    }

    function removeDebtor(address debtor) private {
        address lastDebtor = debtorAddrs[debtorAddrs.length - 1];
        debtorAddrs[debtors[debtor].index] = lastDebtor;
        delete debtorAddrs[debtorAddrs.length - 1];
    }

    function addRequestor(address requestor) private {
        requestorAddrs.push(requestor);
        requestors[requestor].index = requestorAddrs.length - 1;
    }

    function removeRequestor(address requestor) private {
        address lastRequestor = requestorAddrs[requestorAddrs.length - 1];
        requestorAddrs[requestors[requestor].index] = lastRequestor;
        delete requestorAddrs[requestorAddrs.length - 1];
    }

    function resetRequestor(address requestor) private {
        requestors[requestor].votesYea = 0;
        requestors[requestor].votesNay = 0;
        requestors[requestor].requestAmount = 0;
        requestors[requestor].index = 0;
        // TODO: Do we need to selfdestruct the whoVoted subcontract?
    }

    function resetDebtor(address debtor) private {
        debtors[debtor].loanAmount = 0;
        debtors[debtor].balance = 0;
        debtors[debtor].interest = 0;
        debtors[debtor].outstandingLoanAmount = 0;
        debtors[debtor].outstandingInterestAmount = 0;
    }
}
