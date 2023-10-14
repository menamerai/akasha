// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Record.sol";

contract Akasha {
    mapping(address => Record[]) public records;
    mapping(address => uint256) public recordCount;

    event RecordAdded(address indexed _from, string _title, string _description, uint256 _timestamp);

    function addRecord(string memory _title, string memory _description) public {
        Record newRecord = new Record(_title, _description);
        records[msg.sender].push(newRecord);
        
        emit RecordAdded(msg.sender, _title, _description, block.timestamp);
    }
}
