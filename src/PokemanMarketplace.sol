// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./PokemanNFT.sol";

contract PokemanMarketplace is ReentrancyGuard {
    IERC721 public immutable pokemanNFT;
    IERC20 public immutable pokeToken;
    PokemanNFT public immutable pokemanNFTContract;

    struct Listing {
        address seller;
        uint256 price;
    }

    // tokenId => Listing
    mapping(uint256 => Listing) public listings;

    event Listed(address indexed seller, uint256 indexed tokenId, uint256 price);
    event Sale(address indexed buyer, uint256 indexed tokenId, uint256 price);
    event Cancelled(address indexed seller, uint256 indexed tokenId);

    constructor(address _pokemanNFT, address _pokeToken) {
        pokemanNFT = IERC721(_pokemanNFT);
        pokeToken = IERC20(_pokeToken);
        pokemanNFTContract = PokemanNFT(_pokemanNFT);
    }

    // List an NFT for sale
    function list(uint256 tokenId, uint256 price) external {
        address nftOwner = pokemanNFT.ownerOf(tokenId);
        require(price > 0, "Price must be > 0");
        require(listings[tokenId].seller == address(0), "Already listed");
        if (nftOwner == msg.sender) {
            // User is the owner, transfer NFT to marketplace for escrow
            pokemanNFT.transferFrom(msg.sender, address(this), tokenId);
            listings[tokenId] = Listing({seller: msg.sender, price: price});
            emit Listed(msg.sender, tokenId, price);
        } else if (nftOwner == address(pokemanNFTContract)) {
            // NFT is held by PokemanNFT contract, only PokemanNFT owner can list
            require(msg.sender == pokemanNFTContract.owner(), "Only PokemanNFT owner can list contract-held NFT");
            pokemanNFT.safeTransferFrom(address(pokemanNFTContract), address(this), tokenId);
            listings[tokenId] = Listing({seller: msg.sender, price: price});
            emit Listed(msg.sender, tokenId, price);
        } else {
            revert("Not NFT owner or contract-held");
        }
    }

    // Buy a listed NFT
    function buy(uint256 tokenId) external nonReentrant {
        Listing memory listing = listings[tokenId];
        require(listing.seller != address(0), "Not listed");
        require(listing.seller != msg.sender, "Cannot buy your own NFT");
        // Transfer POKEs from buyer to seller
        require(pokeToken.transferFrom(msg.sender, listing.seller, listing.price), "POKE transfer failed");
        // Transfer NFT to buyer
        pokemanNFT.transferFrom(address(this), msg.sender, tokenId);
        delete listings[tokenId];
        emit Sale(msg.sender, tokenId, listing.price);
    }

    // Cancel a listing
    function cancel(uint256 tokenId) external {
        Listing memory listing = listings[tokenId];
        require(listing.seller == msg.sender, "Not seller");
        // Transfer NFT back to seller
        pokemanNFT.transferFrom(address(this), msg.sender, tokenId);
        delete listings[tokenId];
        emit Cancelled(msg.sender, tokenId);
    }

    // View function to check if a token is listed
    function isListed(uint256 tokenId) external view returns (bool) {
        return listings[tokenId].seller != address(0);
    }
} 