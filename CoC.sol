// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

contract CoC {
    uint private caseCount;
    mapping (uint => string) private CaseUUIDList; // All uuid of cases
    mapping(string => Case) private CaseList; // All cases

    struct Case {
        string caseName;
        string caseDetails;
        string[] EvidenceUUIDList; // All unique evidences
        string[] OfficerUUIDList; // Uuid of users that are allowed to handle the case
        mapping(string => bool) OfficerExists;
        Evidence[] LogList; // All evidence transactions
        bool caseClosed;
    }

    struct Evidence {
        string uuid;
        string evidenceName;
        string timestamp;
        string eventLog;
        string ipAddress;
        string evidenceHash;
        string evidenceDescription;
        string owner;
        string locTime;
        string actionBy;
    }

    constructor() {
        caseCount = 0;
    }
    
    modifier isCaseClosed(string memory _caseUuid) {
        require(!CaseList[_caseUuid].caseClosed, "Case closed!");
        _;
    }
    
    modifier doesCaseExist(string memory _caseUuid) {
        require(bytes(CaseList[_caseUuid].caseName).length != 0, "Case does not exist!");
        _;
    }
    
    
    // CASES
    
    function AddCase(string memory _caseUuid, string memory _caseName, string[] memory _officerUuid, string memory _caseDetails) external {
        CaseUUIDList[caseCount] = _caseUuid;
        
        Case storage currentCase = CaseList[_caseUuid];
        currentCase.caseName = _caseName;
        currentCase.caseDetails = _caseDetails;
        currentCase.caseClosed = false;
        for (uint i=0; i < _officerUuid.length; i++) {
            currentCase.OfficerUUIDList.push(_officerUuid[i]);
            currentCase.OfficerExists[_officerUuid[i]] = true;
        }
        caseCount++;
    }
    
    function CloseCase(string memory _caseUuid) external doesCaseExist(_caseUuid) {
        Case storage currentCase = CaseList[_caseUuid];
        currentCase.caseClosed = true;
    }
    
    function AddUUIDToCase(string memory _caseUuid, string[] memory _officerUuid) external isCaseClosed(_caseUuid) doesCaseExist(_caseUuid) {
        Case storage currentCase = CaseList[_caseUuid];
        
        for (uint i=0; i < _officerUuid.length; i++) {
            currentCase.OfficerUUIDList.push(_officerUuid[i]);
            currentCase.OfficerExists[_officerUuid[i]] = true;
        }
    }
    
    function EditCaseDetails(string memory _caseUuid, string memory _caseDetails) external isCaseClosed(_caseUuid) doesCaseExist(_caseUuid) {
        Case storage currentCase = CaseList[_caseUuid];
        currentCase.caseDetails = _caseDetails;
    }
    
    function GetCaseDetails(string memory _caseUuid) external doesCaseExist(_caseUuid) 
    view returns (string memory caseDetails) {
        return CaseList[_caseUuid].caseDetails;
    }
    
    function GetCaseInfo(string memory _caseUuid) external doesCaseExist(_caseUuid) 
    view returns (string memory caseName, string[] memory uuid, string memory caseDetails, string[] memory latestEvidences) {
        return (CaseList[_caseUuid].caseName, GetCaseOfficers(_caseUuid), CaseList[_caseUuid].caseDetails, GetAllLatestCaseEvidence(_caseUuid));
    }

    function GetAllCaseUUID() private view returns (string[] memory cases) {
        string[] memory allCases = new string[](caseCount);
        for (uint i=0; i<caseCount; i++) {
            allCases[i] = CaseUUIDList[i];
        }
        return allCases;
    }
    
    function GetAllOfficerCase(string memory _officerUuid) external view returns (string[] memory caseUuid, string[] memory caseName, string[] memory caseDetails,  bool[] memory caseClosed) {
        string[] memory casesUUID = GetAllCaseUUID();
        string[] memory relevantCases = new string[](caseCount);
        
        uint arrayCount = 0;
        for (uint i=0; i<casesUUID.length; i++) {
            if (CaseList[casesUUID[i]].OfficerExists[_officerUuid]) {
                relevantCases[arrayCount] = casesUUID[i];
                arrayCount++;
            }
        }
        
        string[] memory uuid = new string[](arrayCount);
        string[] memory name = new string[](arrayCount);
        string[] memory details = new string[](arrayCount);
        bool[] memory closed = new bool[](arrayCount);
        for (uint i=0; i<arrayCount; i++) {
            uuid[i] = relevantCases[i];
            name[i] = CaseList[relevantCases[i]].caseName;
            details[i] = CaseList[relevantCases[i]].caseDetails;
            closed[i] = CaseList[relevantCases[i]].caseClosed;
        }

        return (uuid, name, details, closed);
    }
    
    function GetCaseOfficers(string memory _caseUuid) public doesCaseExist(_caseUuid)
    view returns (string[] memory allCaseOfficers) {
        return CaseList[_caseUuid].OfficerUUIDList;
    }

    function GetCaseCount() external view returns (uint NumOfCases) {
        return caseCount;
    }
    
    function GetCaseClosed(string memory _caseUuid) external doesCaseExist(_caseUuid)
    view returns (bool caseClosed) {
        return CaseList[_caseUuid].caseClosed;
    }
    
    // EVIDENCES
    
    function LogEvidence(string[] memory _evidence) external isCaseClosed(_evidence[0]) doesCaseExist(_evidence[0])
    returns (uint result) {
        Case storage currentCase = CaseList[_evidence[0]];

        // Uniquely store evidence UUID
        bool storeUUID = true;
        for (uint i=0; i < currentCase.EvidenceUUIDList.length; i++) {
            if (keccak256(bytes(_evidence[1])) == keccak256(bytes(currentCase.EvidenceUUIDList[i]))) {
                storeUUID = false;
                break;
            }
        }
        if (storeUUID) {
            currentCase.EvidenceUUIDList.push(_evidence[1]);
        }
        
        Evidence memory e;
        e.uuid = _evidence[1];
        e.evidenceName = _evidence[2];
        e.timestamp = _evidence[3];
        e.eventLog = _evidence[4];
        e.ipAddress = _evidence[5];
        e.evidenceHash = _evidence[6];
        e.evidenceDescription = _evidence[7];
        e.owner = _evidence[8];
        e.locTime = _evidence[9];
        e.actionBy = _evidence[10];
        
        currentCase.LogList.push(e);
        return 0;
    }
    
    function GetEvidenceCount(string memory _caseUuid) external doesCaseExist(_caseUuid)
    view returns (uint NumOfEvidences) {
        return CaseList[_caseUuid].LogList.length;
    }
    
    function GetAllSimilarEvidence(string memory _caseUuid, string memory _evidenceUuid) external doesCaseExist(_caseUuid)
    view returns (string[] memory retEvidence) {
        Case storage currentCase = CaseList[_caseUuid];
        string[] memory retrievedEvidence = new string[](CaseList[_caseUuid].LogList.length);
        
        uint arrayCount = 0;
        for (uint i = 0; i < currentCase.LogList.length; i++) {
            if (keccak256(bytes(_evidenceUuid)) == keccak256(bytes(currentCase.LogList[i].uuid))) {
                retrievedEvidence[arrayCount] = string(abi.encodePacked(
                currentCase.LogList[i].uuid, "|", 
                currentCase.LogList[i].evidenceName, "|",
                currentCase.LogList[i].timestamp, "|",
                currentCase.LogList[i].eventLog, "|",
                currentCase.LogList[i].evidenceHash, "|",
                currentCase.LogList[i].ipAddress, "|",
                currentCase.LogList[i].evidenceDescription, "|",
                currentCase.LogList[i].owner, "|",
                currentCase.LogList[i].locTime, "|",
                currentCase.LogList[i].actionBy));
                arrayCount++;
            }
        }
        return retrievedEvidence;
    }
    
    function GetAllCaseEvidence(string memory _caseUuid) external doesCaseExist(_caseUuid)
    view returns (string[] memory retEvidence) {
        Case storage currentCase = CaseList[_caseUuid];
        string[] memory retrievedEvidence = new string[](CaseList[_caseUuid].LogList.length);
        
        for (uint i = 0; i < CaseList[_caseUuid].LogList.length; i++) {
            retrievedEvidence[i] = string(
                abi.encodePacked(
                currentCase.LogList[i].uuid, "|", 
                currentCase.LogList[i].evidenceName, "|",
                currentCase.LogList[i].timestamp, "|",
                currentCase.LogList[i].eventLog, "|",
                currentCase.LogList[i].ipAddress, "|",
                currentCase.LogList[i].evidenceHash, "|",
                currentCase.LogList[i].evidenceDescription, "|",
                currentCase.LogList[i].owner, "|",
                currentCase.LogList[i].locTime, "|",
                currentCase.LogList[i].actionBy));
        }
        return retrievedEvidence;
    }
    
    function GetAllLatestCaseEvidence(string memory _caseUuid) public view returns (string[] memory retEvidence) {
        Case storage currentCase = CaseList[_caseUuid];
        string[] memory retrievedEvidence = new string[](currentCase.EvidenceUUIDList.length);
        
        for (uint i = 0; i < currentCase.EvidenceUUIDList.length; i++) {
            for (uint j = currentCase.LogList.length - 1; j >= 0; j--) {
                if (keccak256(bytes(currentCase.EvidenceUUIDList[i])) == keccak256(bytes(currentCase.LogList[j].uuid))) {
                    retrievedEvidence[i] = string(
                        abi.encodePacked(
                        currentCase.LogList[j].uuid, "|", 
                        currentCase.LogList[j].evidenceName, "|",
                        currentCase.LogList[j].timestamp, "|",
                        currentCase.LogList[j].eventLog, "|",
                        currentCase.LogList[j].ipAddress, "|",
                        currentCase.LogList[j].evidenceHash, "|",
                        currentCase.LogList[j].evidenceDescription, "|",
                        currentCase.LogList[j].owner, "|",
                        currentCase.LogList[j].locTime, "|",
                        currentCase.LogList[j].actionBy));
                    break;
                }
            }
        }
        return retrievedEvidence;
    }
    
    function GetLatestCaseEvidence(string memory _caseUuid, string memory _evidenceUuid) external doesCaseExist(_caseUuid)
    view returns (string memory retEvidence) {
        Case storage currentCase = CaseList[_caseUuid];
        
        for (uint i = currentCase.LogList.length - 1; i >= 0; i--) {
            if (keccak256(bytes(_evidenceUuid)) == keccak256(bytes(currentCase.LogList[i].uuid))) {
                return string(
                    abi.encodePacked(
                    currentCase.LogList[i].uuid, "|", 
                    currentCase.LogList[i].evidenceName, "|",
                    currentCase.LogList[i].timestamp, "|",
                    currentCase.LogList[i].eventLog, "|",
                    currentCase.LogList[i].ipAddress, "|",
                    currentCase.LogList[i].evidenceHash, "|",
                    currentCase.LogList[i].evidenceDescription, "|",
                    currentCase.LogList[i].owner, "|",
                    currentCase.LogList[i].locTime, "|",
                    currentCase.LogList[i].actionBy));
            }
        }
    }
}
