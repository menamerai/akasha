// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Akasha {

    struct Record {
        address owner;
        string title;
        string description;
        uint256 timestamp;
        uint256 recordId;
    }
    Record[] public records;
    mapping(uint256 => mapping(address => mapping(string => string))) public flashcards;
    mapping(uint256 => mapping(address => string[])) public questions;
    mapping(uint256 => address[]) public flashcardOwners;
    mapping(address => uint256[]) public recordIds;

    event RecordAdded(address indexed _from, string _title, string _description, uint256 _timestamp, uint256 _recordId);
    event RecordUpdated(address indexed _from, string _oldTitle, string _oldDescription, string _newTitle, string _newDescription, uint256 _timestamp, uint256 _recordId);
    event RecordRemoved(address indexed _from, string _title, string _description, uint256 _timestamp, uint256 _recordId);
    event FlashcardAdded(address indexed _from, string _question, string _answer, uint256 _timestamp, uint256 _recordId);
    event FlashcardRemoved(address indexed _from, string _question, uint256 _timestamp, uint256 _recordId);

    function generateRecordId() private view returns (uint256) {
        uint256 randId = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender)));
        // check if recordId already exists
        for (uint256 i = 0; i < records.length; i++) {
            if (records[i].recordId == randId) {
                return generateRecordId();
            }
        }
        return randId;
    }

    function addRecord(string memory _title, string memory _description) public {
        uint256 _recordId = generateRecordId();
        Record memory record = Record(msg.sender, _title, _description, block.timestamp, _recordId);
        records.push(record);
        recordIds[msg.sender].push(_recordId);
        emit RecordAdded(msg.sender, _title, _description, block.timestamp, _recordId);
    }

    function findRecord(uint256 _recordId) private view returns (Record storage) {
        for (uint256 i = 0; i < records.length; i++) {
            if (records[i].recordId == _recordId) {
                return records[i];
            }
        }
        revert("Record not found");
    }

    function updateRecord(uint256 _recordId, string memory _title, string memory _description) public {
        Record storage record = findRecord(_recordId);
        require(msg.sender == record.owner, "Only the owner can update the record");
        string memory _oldTitle = record.title;
        string memory _oldDescription = record.description;
        record.title = _title;
        record.description = _description;
        record.timestamp = block.timestamp;
        emit RecordUpdated(msg.sender, _oldTitle, _oldDescription, _title, _description, block.timestamp, _recordId);
    }

    function removeRecord(uint256 _recordId) public { // this is so gas inefficient it's not even funny
        Record memory record = findRecord(_recordId);
        require(msg.sender == record.owner, "Only the owner can remove the record");
        for (uint256 i = 0; i < records.length; i++) {
            if (records[i].recordId == _recordId) {
                // delete all flashcards from all flashcardOwners
                for (uint256 j = 0; j < flashcardOwners[_recordId].length; j++) {
                    for (uint256 k = 0; k < questions[_recordId][flashcardOwners[_recordId][j]].length; k++) {
                        delete flashcards[_recordId][flashcardOwners[_recordId][j]][questions[_recordId][flashcardOwners[_recordId][j]][k]];
                        emit FlashcardRemoved(msg.sender, questions[_recordId][flashcardOwners[_recordId][j]][k], block.timestamp, _recordId);
                    }
                    delete questions[_recordId][flashcardOwners[_recordId][j]];
                }
                delete flashcardOwners[_recordId];
                records[i] = records[records.length - 1];
                records.pop();
                break;
            }
        }
        emit RecordRemoved(msg.sender, record.title, record.description, block.timestamp, _recordId);
    }

    function addFlashcardToRecord(uint256 _recordId, string memory _question, string memory _answer) public {
        Record memory record = findRecord(_recordId); // check if record exists
        // add user to flashcardOwners if not already added
        bool userExists = false;
        for (uint256 i = 0; i < flashcardOwners[_recordId].length; i++) {
            if (flashcardOwners[_recordId][i] == msg.sender) {
                userExists = true;
                break;
            }
        }
        if (!userExists) {
            flashcardOwners[_recordId].push(msg.sender);
        }
        // add flashcard to user's flashcards
        flashcards[_recordId][msg.sender][_question] = _answer;
        questions[_recordId][msg.sender].push(_question);
        emit FlashcardAdded(msg.sender, _question, _answer, block.timestamp, _recordId);
    }

    function removeFlashcardFromRecord(uint256 _recordId, string memory _question) public {
        require(bytes(flashcards[_recordId][msg.sender][_question]).length > 0, "Flashcard does not exist");
        Record memory record = findRecord(_recordId); // check if record exists
        // remove flashcard from user's flashcards
        delete flashcards[_recordId][msg.sender][_question];
        for (uint256 i = 0; i < questions[_recordId][msg.sender].length; i++) {
            if (keccak256(abi.encodePacked(questions[_recordId][msg.sender][i])) == keccak256(abi.encodePacked(_question))) {
                questions[_recordId][msg.sender][i] = questions[_recordId][msg.sender][questions[_recordId][msg.sender].length - 1];
                questions[_recordId][msg.sender].pop();
                break;
            }
        }
        emit FlashcardRemoved(msg.sender, _question, block.timestamp, _recordId);
    }

    function getAllFlashcardsFromRecord(uint256 _recordId) public view returns (string[] memory, string[] memory) {
        Record memory record = findRecord(_recordId); // check if record exists
        // get all flashcards from user's flashcards
        string[] memory _questions = new string[](questions[_recordId][msg.sender].length);
        string[] memory _answers = new string[](questions[_recordId][msg.sender].length);
        for (uint256 i = 0; i < questions[_recordId][msg.sender].length; i++) {
            _questions[i] = questions[_recordId][msg.sender][i];
            _answers[i] = flashcards[_recordId][msg.sender][questions[_recordId][msg.sender][i]];
        }
        return (_questions, _answers);
    }

    function getAllRecordsFromAddress(address _address) public view returns (uint256[] memory, string[] memory, string[] memory, uint256[] memory) {
        require(recordIds[_address].length > 0, "No records found");
        uint256[] memory _recordIds = new uint256[](recordIds[_address].length);
        string[] memory _titles = new string[](recordIds[_address].length);
        string[] memory _descriptions = new string[](recordIds[_address].length);
        uint256[] memory _timestamps = new uint256[](recordIds[_address].length);
        for (uint256 i = 0; i < recordIds[_address].length; i++) {
            _recordIds[i] = records[i].recordId;
            _titles[i] = records[i].title;
            _descriptions[i] = records[i].description;
            _timestamps[i] = records[i].timestamp;
        }
        return (_recordIds, _titles, _descriptions, _timestamps);
    }
}
