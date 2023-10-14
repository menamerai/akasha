// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Flashcards.sol";

contract Record {
    address public owner;
    string public title;
    string public description;
    mapping(address => Flashcards) public flashcards;

    event RecordUpdated(address indexed _from, string _oldTitle, string _oldDescription, string _newTitle, string _newDescription, uint256 _timestamp);

    constructor(string memory _title, string memory _description) {
        owner = msg.sender;
        title = _title;
        description = _description;
    }

    function update(string memory _title, string memory _description) public {
        require(msg.sender == owner, "Only the owner can update the record");
        string memory _oldTitle = title;
        string memory _oldDescription = description;
        title = _title;
        description = _description;
        emit RecordUpdated(msg.sender, _oldTitle, _oldDescription, _title, _description, block.timestamp);
    }

    function addFlashcard(string memory _question, string memory _answer) public {
        // add user to flashcards mapping if not already added
        if (flashcards[msg.sender] == Flashcards(address(0))) {
            flashcards[msg.sender] = new Flashcards();
        }
        // add flashcard to user's flashcards
        flashcards[msg.sender].addFlashcard(_question, _answer);
    }

    function removeFlashcard(string memory _question) public {
        // remove flashcard from user's flashcards
        flashcards[msg.sender].removeFlashcard(_question);
    }
}
