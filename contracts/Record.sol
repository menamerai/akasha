// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
import "hardhat/console.sol";

// A contract called Record that contains a struct storing information on a certain subject - like a wiki page
// The struct should also contain a uint that acts as a timestamp.
// There should also include a mapping that maps an address to a question - answer tuple pair
// representing a flashcard question and answer added by the user

contract Record {
    address public owner;
    struct RecordStruct {
        string title;
        string description;
        uint timestamp;
    }

    mapping(address => mapping(string => mapping(address => mapping (string => string)))) public flashcards; // address => record title => address => question => answer
    RecordStruct[] public records;

    constructor() {
        owner = msg.sender;
    }

    function addRecord(
        string memory _title,
        string memory _description,
        uint _timestamp
    ) public {
        require(msg.sender == owner, "You are not the owner of the contract");
        records.push(RecordStruct(_title, _description, _timestamp));
    }

    function addFlashcard(
        string memory _question, 
        string memory _answer,
        string memory _title
    ) public {
        // check if the record title exists
        for (uint i = 0; i < records.length; i++) {
            if (keccak256(abi.encodePacked(records[i].title)) == keccak256(abi.encodePacked(_title))) {
                // check if the question exists
                if (keccak256(abi.encodePacked(flashcards[msg.sender][_title][msg.sender][_question])) == keccak256(abi.encodePacked(_question))) {
                    revert("Question already exists");
                } else {
                    flashcards[msg.sender][_title][msg.sender][_question] = _answer;
                }
            } else {
                revert("Record title does not exist");
            }
        }
    }

    function getFlashcard(
        string memory _question,
        string memory _title
    ) public view returns (string memory) {
        return flashcards[msg.sender][_title][msg.sender][_question];
    }

    function getAllRecordTitles() public view returns (string[] memory) {
        string[] memory titles = new string[](records.length);
        for (uint i = 0; i < records.length; i++) {
            titles[i] = records[i].title;
        }
        return titles;
    }

    function getRecord(uint _index) public view returns (string memory, string memory, uint) {
        return (records[_index].title, records[_index].description, records[_index].timestamp);
    }

    function getRecordCount() public view returns (uint) {
        return records.length;
    }

    function getAllFlashcardAnswers(string memory _title) public view returns (string[] memory) {
        string[] memory answers = new string[](records.length);
        for (uint i = 0; i < records.length; i++) {
            answers[i] = flashcards[msg.sender][_title][msg.sender][records[i].title];
        }
        return answers;
    }

    function getAllFlashcardQuestions(string memory _title) public view returns (string[] memory) {
        string[] memory questions = new string[](records.length);
        for (uint i = 0; i < records.length; i++) {
            questions[i] = flashcards[msg.sender][_title][msg.sender][records[i].title];
        }
        return questions;
    }
}
