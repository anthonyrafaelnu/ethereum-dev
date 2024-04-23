// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

contract Tarea {
    address owner;
    mapping(address => uint) tokenBalances;

    constructor(){
        owner = msg.sender;
        tokenBalances[owner] = 1000;
    }

    modifier onlyOwner {
        require(msg.sender == owner,"Solo el owner puede realizar esta accion");
        _;
    }

    event MinteenToken(address sender, uint balance);
    event TokenTransfer(address sender, address dest, uint balance);

    function VerifyAddressTokenBalance(address origin) view external returns(uint) {
        return tokenBalances[origin];
    }

    function SendTokens(address dest, uint value) external {
        require (value <= tokenBalances[msg.sender], "No tiene saldo suficiente para realizar esta operacion");
        tokenBalances[dest] += value;
        tokenBalances[msg.sender] -= value;
        emit TokenTransfer(msg.sender, dest, value);
    }

    function addTokens(uint balance) external onlyOwner {
        tokenBalances[owner] += balance;
        emit MinteenToken(msg.sender, balance);
    }
}