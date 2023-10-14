// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Record.sol";

contract Akasha {
    mapping(address => Record[]) public records;

    event RecordAdded(address indexed _from, string _title, string _description, uint256 _timestamp);
    event RecordRemoved(address indexed _from, string _title, string _description, uint256 _timestamp);

    function getRecordFromRecordAddress(address _recordAddress) public view returns (Record) {
        for (uint256 i = 0; i < records[msg.sender].length; i++) {
            if (address(records[msg.sender][i]) == _recordAddress) {
                return records[msg.sender][i];
            }
        }
        revert("Record not found");
    }

    function addRecord(string memory _title, string memory _description) public {
        Record newRecord = new Record(msg.sender, _title, _description);
        records[msg.sender].push(newRecord);
        emit RecordAdded(msg.sender, _title, _description, block.timestamp);
    }

    function getAllRecords() public view returns (Record[] memory, string[] memory, uint256[] memory) {
        Record[] memory _records = records[msg.sender];
        string[] memory titles = new string[](_records.length);
        uint256[] memory timestamps = new uint256[](_records.length);
        for (uint256 i = 0; i < _records.length; i++) {
            titles[i] = _records[i].title();
            timestamps[i] = _records[i].timestamp();
        }
        return (_records, titles, timestamps);
    }

    function updateRecord(address _recordAddress, string memory _title, string memory _description) public {
        Record record = getRecordFromRecordAddress(_recordAddress);
        require(msg.sender == record.owner(), "Only the owner can update the record");
        record.update(_title, _description);
    }

    function removeRecord(uint256 _index) public {
        require(_index < records[msg.sender].length, "Index out of bounds");
        Record record = records[msg.sender][_index];
        records[msg.sender][_index] = records[msg.sender][records[msg.sender].length - 1];
        records[msg.sender].pop();
        emit RecordRemoved(msg.sender, record.title(), record.description(), block.timestamp);
    }

    function addFlashcardToRecord(uint _index, string memory _question, string memory _answer) public {
        Record record = records[msg.sender][_index];
        require(msg.sender == record.owner(), "Only the owner can add flashcards to the record");
        record.addFlashcard(_question, _answer);
    }

    function getAllFlashcardsFromRecord(address _recordAddress) public view returns (string[] memory, string[] memory) {
        Record record = getRecordFromRecordAddress(_recordAddress);
        return record.getAllFlashcards();
    }

    function removeFlashcardFromRecord(address _recordAddress, string memory _question) public {
        Record record = getRecordFromRecordAddress(_recordAddress);
        require(msg.sender == record.owner(), "Only the owner can remove flashcards from the record");
        record.removeFlashcard(_question);
    }
}
