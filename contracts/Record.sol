// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
import "hardhat/console.sol";

// A contract called Record that contains information on a certain subject - like a wiki page
// it has a title, description, and timestamp
// There should also include a mapping that maps an address to a question - answer tuple pair
// representing a flashcard question and answer added by the user
// try to keep the contract as simple and as gas efficient as possible

contract Record {
    address public owner;
    string public title;
    string public description;
    uint256 public timestamp;
    mapping(address => mapping(string => string)) public flashcards;
    mapping(address => string[]) public questions;
    

    constructor(
        string memory _title,
        string memory _description
    ) {
        owner = msg.sender;
        title = _title;
        description = _description;
        timestamp = block.timestamp;
    }

    function getAllQuestions() public view returns (string[] memory) {
        return questions[msg.sender];
    }

    function addFlashcard(string memory _question, string memory _answer) public {
        // check if the question is already in the mapping
        require(
            keccak256(abi.encodePacked(flashcards[msg.sender][_question])) ==
                keccak256(abi.encodePacked("")),
            "Question already exists"
        );

        // add the question and answer to the mapping
        flashcards[msg.sender][_question] = _answer;
        questions[msg.sender].push(_question);
    }

    function removeFlashcard(string memory _question) public {
        // check if the question is already in the mapping
        require(
            keccak256(abi.encodePacked(flashcards[msg.sender][_question])) !=
                keccak256(abi.encodePacked("")),
            "Question does not exist"
        );

        // remove the question and answer from the mapping
        delete flashcards[msg.sender][_question];
        // remove the question from the questions array
        for (uint256 i = 0; i < questions[msg.sender].length; i++) {
            if (
                keccak256(abi.encodePacked(questions[msg.sender][i])) ==
                keccak256(abi.encodePacked(_question))
            ) {
                delete questions[msg.sender][i];
            }
        }
    }

    function getAllFlashcards() public view returns (string[] memory, string[] memory) {
        string[] memory _questions = questions[msg.sender];
        string[] memory _answers = new string[](_questions.length);
        for (uint256 i = 0; i < _questions.length; i++) {
            _answers[i] = flashcards[msg.sender][_questions[i]];
        }
        return (_questions, _answers);
    }
}
