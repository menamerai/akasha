// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Flashcards {
    address public owner;
    mapping(string => string) private flashcards;
    string[] public questions;

    event FlashcardAdded(address indexed _from, string _question, string _answer, uint256 _timestamp);
    event FlashcardRemoved(address indexed _from, string _question, uint256 _timestamp);

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    function addFlashcard(string memory question, string memory answer) public onlyOwner {
        flashcards[question] = answer;
        questions.push(question);
        emit FlashcardAdded(msg.sender, question, answer, block.timestamp);
    }

    function removeFlashcard(string memory question) public onlyOwner {
        delete flashcards[question];
        for (uint256 i = 0; i < questions.length; i++) {
            if (keccak256(abi.encodePacked(questions[i])) == keccak256(abi.encodePacked(question))) {
                questions[i] = questions[questions.length - 1];
                questions.pop();
                break;
            }
        }
        emit FlashcardRemoved(msg.sender, question, block.timestamp);
    }

    function getAnswer(string memory question) public view returns (string memory) {
        return flashcards[question];
    }

    function getAllFlashcards() public view onlyOwner returns (string[] memory, string[] memory) {
        string[] memory _questions = new string[](questions.length);
        string[] memory _answers = new string[](questions.length);
        for (uint256 i = 0; i < questions.length; i++) {
            _questions[i] = questions[i];
            _answers[i] = flashcards[questions[i]];
        }
        return (_questions, _answers);
    }
}
