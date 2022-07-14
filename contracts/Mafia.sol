//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

error MintingClosed();
error AmountNotAvailable();
error AmountOutOfBounds(uint256 amount);
error MerkleProofFailed();
error ValueNotEqualToPrice(uint256 price, uint256 value);
error NotEnoughBalance(uint256 requested, uint256 balance);
error AlreadyMintedInPhase();
error NotAllowedToMintAmount(uint256 available);

// A simple token contract
contract Mafia is ERC721, Ownable, ReentrancyGuard {
    enum Status {
        CLOSED, // 0
        WHITELIST, // 1
        FREE, // 2
        PAID // 3
    }

    // Status
    Status public status = Status.CLOSED;

    // Parameters
    string private baseTokenURI;
    bytes32 private merkleRoot;
    uint256 public totalSupply = 4444;
    uint256 public freeSupply = 2222;
    uint256 public reserved = 50;
    uint256 public price = 0.0044 ether;
    uint256 public currentTokenId = reserved;
    uint256 public maxPerWallet = 2;

    // Mappings
    mapping(address => bool) private hasMintedWhiteList;
    mapping(address => bool) private hasMintedFree;
    mapping(address => uint256) private hasMintedPublic;

    // Event declaration
    event ChangedPrice(uint256 price);
    event ChangedStatus(Status newStatus);
    event ChangedBaseURI(string newURI);
    event ChangedMerkleRoot(bytes32 newMerkleRoot);
    event ChangedTeamWalletAddress(address newAddress);
    event WithdrawnAmount(uint256 amount, address to);

    /**
     * Contract initialization.
     */
    constructor() ERC721("MAFIA.WTF", "MAF") {}

    function mint(bytes32[] calldata _proof, uint256 _amount) external payable nonReentrant {
        // General Requirements
        if (status == Status.CLOSED) revert MintingClosed();
        if (currentTokenId + _amount < totalSupply) revert AmountNotAvailable();
        if (msg.value != _amount * price) revert ValueNotEqualToPrice(_amount * price, msg.value);

        // Status-specific Requirements
        if (status == Status.WHITELIST) {
            if (!verifyMerkleProof(_proof)) revert MerkleProofFailed();
            if (hasMintedWhiteList[msg.sender]) revert AlreadyMintedInPhase();
            hasMintedWhiteList[msg.sender] = true;
        } else if (status == Status.FREE) {
            if (hasMintedFree[msg.sender]) revert AlreadyMintedInPhase();
            hasMintedFree[msg.sender] = true;
        } else if (status == Status.PAID) {
            if (hasMintedPublic[msg.sender] + _amount > 2)
                revert NotAllowedToMintAmount(2 - hasMintedPublic[msg.sender]);
            if (_amount < 1 || _amount > maxPerWallet) revert AmountOutOfBounds(_amount);

            hasMintedPublic[msg.sender] += _amount;
        }

        // Mint
        for (uint256 i; i < _amount; ) {
            _safeMint(msg.sender, currentTokenId + i);
            unchecked {
                ++i;
            }
        }
        unchecked {
            currentTokenId += _amount;
        }
    }

    function ownerMint(uint256 _amount) external nonReentrant onlyOwner {
        if (currentTokenId + _amount > totalSupply) revert AmountNotAvailable();
        if (_amount > reserved) revert AmountNotAvailable();
        for (uint256 i; i < _amount; ) {
            unchecked {
                ++i;
            }
            _safeMint(msg.sender, currentTokenId + i);
        }
        unchecked {
            currentTokenId += _amount;
        }
    }

    // Public
    function verifyMerkleProof(bytes32[] calldata _proof) public view returns (bool) {
        return MerkleProof.verify(_proof, merkleRoot, keccak256(abi.encodePacked(msg.sender)));
    }

    // Internal
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    // Setters
    function setStatus(uint256 _status) external onlyOwner {
        status = Status(_status);
        emit ChangedStatus(status);
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
        emit ChangedPrice(_price);
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
        emit ChangedMerkleRoot(_root);
    }

    function setTokenURI(string memory _newTokenURI) external onlyOwner {
        baseTokenURI = _newTokenURI;
        emit ChangedBaseURI(_newTokenURI);
    }

    // Withdraw Funds From Contract
    function withdraw() external nonReentrant onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        emit WithdrawnAmount(address(this).balance, msg.sender);
    }

    function withdrawAmountToAddress(uint256 _amount, address _to) external nonReentrant onlyOwner {
        if (_amount > address(this).balance)
            revert NotEnoughBalance(_amount, address(this).balance);
        payable(_to).transfer(_amount);
        emit WithdrawnAmount(_amount, _to);
    }
}
