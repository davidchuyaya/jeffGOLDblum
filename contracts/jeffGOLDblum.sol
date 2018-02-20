pragma solidity ^0.4.21;


contract JeffGOLDblum {
    struct Creditor {
        uint balance;
        uint index;
    }

    address[] public creditorAddrs;
    mapping(address => Creditor) private creditors;
    mapping(address => uint) public debtor;

    function JeffGOLDblum() public {
        creditorAddrs = new address[](0);
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

    function deposit() public payable {
        if (msg.value == 0)
            return;
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


}
