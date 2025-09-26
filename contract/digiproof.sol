// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title DigiProof
 * @dev A smart contract for digital document verification and proof of authenticity
 */
contract DigiProof {
    
    // Struct to store document information
    struct Document {
        bytes32 documentHash;
        address owner;
        uint256 timestamp;
        string title;
        bool exists;
    }
    
    // Mapping from document hash to Document struct
    mapping(bytes32 => Document) private documents;
    
    // Mapping from owner address to array of document hashes
    mapping(address => bytes32[]) private ownerDocuments;
    
    // Events
    event DocumentRegistered(bytes32 indexed documentHash, address indexed owner, string title, uint256 timestamp);
    event DocumentVerified(bytes32 indexed documentHash, address indexed verifier, uint256 timestamp);
    event OwnershipTransferred(bytes32 indexed documentHash, address indexed previousOwner, address indexed newOwner);
    
    // Modifiers
    modifier onlyDocumentOwner(bytes32 _documentHash) {
        require(documents[_documentHash].owner == msg.sender, "Only document owner can perform this action");
        _;
    }
    
    modifier documentExists(bytes32 _documentHash) {
        require(documents[_documentHash].exists, "Document does not exist");
        _;
    }
    
    /**
     * @dev Register a new document on the blockchain
     * @param _documentHash The SHA-256 hash of the document
     * @param _title The title/name of the document
     */
    function registerDocument(bytes32 _documentHash, string memory _title) external {
        require(_documentHash != bytes32(0), "Invalid document hash");
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(!documents[_documentHash].exists, "Document already exists");
        
        // Create new document
        documents[_documentHash] = Document({
            documentHash: _documentHash,
            owner: msg.sender,
            timestamp: block.timestamp,
            title: _title,
            exists: true
        });
        
        // Add to owner's document list
        ownerDocuments[msg.sender].push(_documentHash);
        
        emit DocumentRegistered(_documentHash, msg.sender, _title, block.timestamp);
    }
    
    /**
     * @dev Verify if a document exists and return its details
     * @param _documentHash The SHA-256 hash of the document to verify
     * @return exists Whether the document exists
     * @return owner The address of the document owner
     * @return timestamp When the document was registered
     * @return title The title of the document
     */
    function verifyDocument(bytes32 _documentHash) external returns (bool exists, address owner, uint256 timestamp, string memory title) {
        Document memory doc = documents[_documentHash];
        
        if (doc.exists) {
            emit DocumentVerified(_documentHash, msg.sender, block.timestamp);
        }
        
        return (doc.exists, doc.owner, doc.timestamp, doc.title);
    }
    
    /**
     * @dev Transfer ownership of a document to another address
     * @param _documentHash The hash of the document to transfer
     * @param _newOwner The address of the new owner
     */
    function transferOwnership(bytes32 _documentHash, address _newOwner) external 
        documentExists(_documentHash) 
        onlyDocumentOwner(_documentHash) 
    {
        require(_newOwner != address(0), "New owner cannot be zero address");
        require(_newOwner != msg.sender, "Cannot transfer to yourself");
        
        address previousOwner = documents[_documentHash].owner;
        documents[_documentHash].owner = _newOwner;
        
        // Remove from previous owner's list
        _removeFromOwnerList(previousOwner, _documentHash);
        
        // Add to new owner's list
        ownerDocuments[_newOwner].push(_documentHash);
        
        emit OwnershipTransferred(_documentHash, previousOwner, _newOwner);
    }
    
    /**
     * @dev Get all documents owned by a specific address
     * @param _owner The address to query
     * @return Array of document hashes owned by the address
     */
    function getOwnerDocuments(address _owner) external view returns (bytes32[] memory) {
        return ownerDocuments[_owner];
    }
    
    /**
     * @dev Get detailed information about a document (view function)
     * @param _documentHash The hash of the document
     * @return exists Whether the document exists
     * @return owner The owner of the document
     * @return timestamp When it was registered
     * @return title The document title
     */
    function getDocumentInfo(bytes32 _documentHash) external view returns (bool exists, address owner, uint256 timestamp, string memory title) {
        Document memory doc = documents[_documentHash];
        return (doc.exists, doc.owner, doc.timestamp, doc.title);
    }
    
    /**
     * @dev Internal function to remove a document hash from an owner's list
     * @param _owner The owner's address
     * @param _documentHash The document hash to remove
     */
    function _removeFromOwnerList(address _owner, bytes32 _documentHash) internal {
        bytes32[] storage ownerDocs = ownerDocuments[_owner];
        for (uint256 i = 0; i < ownerDocs.length; i++) {
            if (ownerDocs[i] == _documentHash) {
                ownerDocs[i] = ownerDocs[ownerDocs.length - 1];
                ownerDocs.pop();
                break;
            }
        }
    }
    
    /**
     * @dev Get the total number of documents registered by an owner
     * @param _owner The owner's address
     * @return The count of documents
     */
    function getOwnerDocumentCount(address _owner) external view returns (uint256) {
        return ownerDocuments[_owner].length;
    }
}
