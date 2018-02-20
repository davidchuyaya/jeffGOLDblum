pragma solidity ^0.4.0;

contract jeffGOLDblum {

    address[] public creditors;
    mapping(address => uint) private creditorBalances;
    mapping(address => uint) public loaners;

    function jeffGOLDblum(address[] _creditors) {
        creditors = _creditors;
    }

    function deposit() public payable {
        creditorBalances[msg.sender] += msg.value;
    }

    function withdraw() public {
        msg.sender.send(creditBalances[msg.sender]);
    }


}
