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
    struct Flashcard {
        address owner;
        string question;
        string answer;
        uint256 timestamp;
        uint256 correspondingRecordId;
        uint256 flashcardId;
    }
    Record[] public records;
    uint256 public recordCount;
    Flashcard[] public flashcards;
    mapping(uint256 => address[]) public flashcardOwners;
    mapping(address => uint256[]) public recordIds;
    mapping(address => uint256[]) public flashcardIds;

    event RecordAdded(address indexed _from, string _title, string _description, uint256 _timestamp, uint256 _recordId);
    event RecordUpdated(address indexed _from, string _oldTitle, string _oldDescription, string _newTitle, string _newDescription, uint256 _timestamp, uint256 _recordId);
    event RecordRemoved(address indexed _from, string _title, string _description, uint256 _timestamp, uint256 _recordId);
    event FlashcardAdded(address indexed _from, string _question, string _answer, uint256 _timestamp, uint256 _recordId);
    event FlashcardRemoved(address indexed _from, string _question, uint256 _timestamp, uint256 _recordId);

    // helper functions

    function generateId(bool isRecord) private view returns (uint256) {
        uint256 randId = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender)));
        // check if recordId already exists
        if (isRecord) {
            for (uint256 i = 0; i < records.length; i++) {
                if (records[i].recordId == randId) {
                    randId = generateId(isRecord);
                }
            }
        } else {
            for (uint256 i = 0; i < flashcards.length; i++) {
                if (flashcards[i].flashcardId == randId) {
                    randId = generateId(isRecord);
                }
            }
        }
        return randId;
    }

    // record functions

    function addRecord(string memory _title, string memory _description) public {
        uint256 _recordId = generateId(true);
        Record memory record = Record(msg.sender, _title, _description, block.timestamp, _recordId);
        records.push(record);
        recordIds[msg.sender].push(_recordId);
        recordCount++;
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
        delete flashcardOwners[_recordId];
        uint256[] memory _flashcardIds = flashcardIds[msg.sender];
        for (uint256 i = 0; i < _flashcardIds.length; i++) { // this is giving me a headache
            removeFlashcard(_flashcardIds[i]);
        }
        bool found = false;
        for (uint256 i = 0; i < records.length; i++) {
            if (_recordId == records[i].recordId) {
                found = true;
                Record memory record = records[i];
                require(msg.sender == record.owner, "Only the owner can remove the record");
                string memory _title = record.title;
                string memory _description = record.description;
                record.timestamp = block.timestamp;
                // remove record from records manually
                for (uint256 j = i; j < records.length - 1; j++) {
                    records[j] = records[j + 1];
                }
                records.pop();
                recordCount--;
                emit RecordRemoved(msg.sender, _title, _description, block.timestamp, _recordId);
            }
        }
        require(found, "Record not found");
        for (uint256 i = 0; i < recordIds[msg.sender].length; i++) {
            if (recordIds[msg.sender][i] == _recordId) {
                for (uint256 j = i; j < recordIds[msg.sender].length - 1; j++) {
                    recordIds[msg.sender][j] = recordIds[msg.sender][j + 1];
                }
                recordIds[msg.sender].pop();
            }
        }
    }

    function getAllRecordsFromAddress(address _owner) public view returns (Record[] memory) {
        Record[] memory _records = new Record[](recordIds[_owner].length);
        for (uint256 i = 0; i < recordIds[_owner].length; i++) {
            _records[i] = findRecord(recordIds[_owner][i]);
        }
        return _records;
    }

    // flashcard functions

    function addFlashcard(uint256 _recordId, string memory _question, string memory _answer) public {
        Record memory record = findRecord(_recordId);
        uint256 _flashcardId = generateId(false);
        Flashcard memory flashcard = Flashcard(msg.sender, _question, _answer, block.timestamp, _recordId, _flashcardId);
        flashcards.push(flashcard);
        flashcardIds[msg.sender].push(_flashcardId);
        // add msg.sender to flashcardOwners if not already there
        bool found = false;
        for (uint256 i = 0; i < flashcardOwners[_recordId].length; i++) {
            if (flashcardOwners[_recordId][i] == msg.sender) {
                found = true;
            }
        }
        if (!found) {
            flashcardOwners[_recordId].push(msg.sender);
        }
        emit FlashcardAdded(msg.sender, _question, _answer, block.timestamp, _recordId);
    }

    function updateFlashcard(uint256 _flashcardId, string memory _newTitle, string memory _newDesc) public {
        bool found = false;
        for (uint256 i = 0; i < flashcards.length; i++) {
            if (flashcards[i].flashcardId == _flashcardId) {
                require(msg.sender == flashcards[i].owner, "Only the owner can update the flashcard");
                found = true;
                Flashcard storage flashcard = flashcards[i];
                string memory _oldTitle = flashcards[i].question;
                string memory _oldDesc = flashcards[i].answer;
                flashcard.question = _newTitle;
                flashcard.answer = _newDesc;
                flashcard.timestamp = block.timestamp;
                emit RecordUpdated(msg.sender, _oldTitle, _oldDesc, _newTitle, _newDesc, block.timestamp, _flashcardId);
            }
        }
        require(found, "Flashcard not found");
    }

    function removeFlashcard(uint256 _flashcardId) public { // by gods this is awful
        bool found = false;
        // look for flashcard in flashcardIds
        for (uint256 i = 0; i < flashcardIds[msg.sender].length; i++) {
            if (flashcardIds[msg.sender][i] == _flashcardId) {
                found = true;
                for (uint256 j = i; j < flashcardIds[msg.sender].length - 1; j++) {
                    flashcardIds[msg.sender][j] = flashcardIds[msg.sender][j + 1];
                }
                flashcardIds[msg.sender].pop();
            }
        }
        require (found, "Flashcard not found");
        // look for flashcard in flashcards
        for (uint256 i = 0; i < flashcards.length; i++) {
            if (flashcards[i].flashcardId == _flashcardId) {
                require(msg.sender == flashcards[i].owner, "Only the owner can remove the flashcard");
                found = true;
                uint256 _recordId = flashcards[i].correspondingRecordId;
                // remove flashcard from flashcards manually
                for (uint256 j = i; j < flashcards.length - 1; j++) {
                    flashcards[j] = flashcards[j + 1];
                }
                flashcards.pop();
                // delete owner from flashcardOwners if no more flashcards
                if (flashcardOwners[_recordId].length == 0) {
                    for (uint256 j = 0; j < flashcardOwners[_recordId].length; j++) {
                        if (flashcardOwners[_recordId][j] == msg.sender) {
                            for (uint256 k = j; k < flashcardOwners[_recordId].length - 1; k++) {
                                flashcardOwners[_recordId][k] = flashcardOwners[_recordId][k + 1];
                            }
                            flashcardOwners[_recordId].pop();
                        }
                    }
                }
                emit FlashcardRemoved(msg.sender, flashcards[i].question, block.timestamp, _flashcardId);
            }
        }
    }

    function getAllFlashcardsFromRecord(uint256 _recordId) public view returns (Flashcard[] memory) {
        Flashcard[] memory _flashcards = new Flashcard[](flashcardOwners[_recordId].length);
        for (uint256 i = 0; i < flashcardOwners[_recordId].length; i++) {
            for (uint256 j = 0; j < flashcards.length; j++) {
                if (flashcards[j].owner == flashcardOwners[_recordId][i]) {
                    _flashcards[i] = flashcards[j];
                }
            }
        }
        return _flashcards;
    }
}
