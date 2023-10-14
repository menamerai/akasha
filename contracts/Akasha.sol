// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Record.sol";

contract Akasha {
    mapping(address => Record[]) public records;

    event RecordAdded(address indexed _from, string _title, string _description, uint256 _timestamp);
    event RecordRemoved(address indexed _from, string _title, string _description, uint256 _timestamp);

    function addRecord(string memory _title, string memory _description) public {
        Record newRecord = new Record(_title, _description);
        records[msg.sender].push(newRecord);
        emit RecordAdded(msg.sender, _title, _description, block.timestamp);
    }

    function getAllRecords() public view returns (Record[] memory) {
        return records[msg.sender];
    }

    function removeRecord(uint256 _index) public {
        require(_index < records[msg.sender].length, "Index out of bounds");
        Record record = records[msg.sender][_index];
        records[msg.sender][_index] = records[msg.sender][records[msg.sender].length - 1];
        records[msg.sender].pop();
        emit RecordRemoved(msg.sender, record.title(), record.description(), block.timestamp);
    }

}
