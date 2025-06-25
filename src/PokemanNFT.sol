// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./PokeToken.sol";

contract PokemanNFT is ERC721, Ownable {
    // --- NFT Minting State ---
    mapping(uint256 => bool) public minted;
    mapping(uint256 => bool) public availableForMint;

    // --- Staking State ---
    mapping(address => uint256) public stakedAmount;
    mapping(address => uint256) public lastMintTime;
    mapping(address => uint256) public stakeTimestamp;

    // --- Configurable Parameters ---
    uint256 public requiredStake = 1e5; // 100,000 POKEs
    uint256 public coolingPeriod = 1 hours;
    PokeToken public pokeToken;

    // --- Metadata ---
    string public constant BASE_URI = "https://pokeapi.co/api/v2/pokemon/";

    // --- Events ---
    event PokemanMinted(address indexed to, uint256 indexed pokemanId);
    event PokemanPreMinted(address indexed to, uint256 indexed pokemanId);
    event PokemanAvailabilitySet(uint256 indexed pokemanId);
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);

    constructor(address _pokeToken) ERC721("PokemanNFT", "PMN") Ownable(msg.sender) {
        pokeToken = PokeToken(_pokeToken);
    }

    // --- Owner Functions ---
    function preMint(uint256[] calldata pokemanIds) external onlyOwner {
        for (uint256 i = 0; i < pokemanIds.length; i++) {
            uint256 pokemanId = pokemanIds[i];
            require(!minted[pokemanId], "PokemanNFT: already minted");
            minted[pokemanId] = true;
            _safeMint(address(this), pokemanId);
            emit PokemanPreMinted(address(this), pokemanId);
        }
    }

    function setAvailableForMint(uint256[] calldata pokemanIds) external onlyOwner {
        for (uint256 i = 0; i < pokemanIds.length; i++) {
            availableForMint[pokemanIds[i]] = true;
            emit PokemanAvailabilitySet(pokemanIds[i]);
        }
    }

    function setRequiredStake(uint256 _amount) external onlyOwner {
        requiredStake = _amount;
    }

    function setCoolingPeriod(uint256 _period) external onlyOwner {
        coolingPeriod = _period;
    }

    // --- Staking Functions ---
    function stake(uint256 amount) external {
        require(amount >= requiredStake, "PokemanNFT: stake at least required amount");
        require(stakedAmount[msg.sender] == 0, "PokemanNFT: already staked");
        pokeToken.transferFrom(msg.sender, address(this), amount);
        stakedAmount[msg.sender] = amount;
        stakeTimestamp[msg.sender] = block.timestamp;
        emit Staked(msg.sender, amount);
    }

    function unstake() external {
        require(stakedAmount[msg.sender] > 0, "PokemanNFT: nothing to unstake");
        require(block.timestamp >= lastMintTime[msg.sender] + coolingPeriod, "PokemanNFT: cooling period not over");
        uint256 amount = stakedAmount[msg.sender];
        stakedAmount[msg.sender] = 0;
        stakeTimestamp[msg.sender] = 0;
        pokeToken.transfer(msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }

    // --- Minting Function ---
    function mint(uint256 pokemanId) external {
        require(availableForMint[pokemanId], "PokemanNFT: not available for minting");
        require(!minted[pokemanId], "PokemanNFT: already minted");
        require(stakedAmount[msg.sender] >= requiredStake, "PokemanNFT: not enough staked");
        require(block.timestamp >= lastMintTime[msg.sender] + coolingPeriod, "PokemanNFT: cooling period not over");
        minted[pokemanId] = true;
        lastMintTime[msg.sender] = block.timestamp;
        _safeMint(msg.sender, pokemanId);
        emit PokemanMinted(msg.sender, pokemanId);
    }
     function approveFromContract(address to, uint256 tokenId) external onlyOwner {
        require(ownerOf(tokenId) == address(this), "PokemanNFT: NFT not owned by contract");
        _approve(to, tokenId,address(this));
    }

    // --- Metadata ---
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_ownerOf(tokenId)!=address(0), "PokemanNFT: URI query for nonexistent token");
        return string(abi.encodePacked(BASE_URI, _toString(tokenId)));
    }

    // --- Internal Helper ---
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
) external pure returns (bytes4) {
    return this.onERC721Received.selector;
}
} 