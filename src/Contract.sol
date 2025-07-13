// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Delegation {
  event ETHReceived(address indexed from, uint256 indexed amount, bytes data);
  event Initialized();

  function initialize() external {
    emit Initialized();
  }

  receive() external payable {
    emit ETHReceived(msg.sender, msg.value, '');
  }
 
  fallback() external payable {
    emit ETHReceived(msg.sender, msg.value, msg.data);
  }
}