// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/PokemanMarketplace.sol";
import "../src/PokemanNFT.sol";
import "../src/PokeToken.sol";

contract PokemanMarketplaceTest is Test {
    PokemanMarketplace public marketplace;
    PokemanNFT public pokemanNFT;
    PokeToken public pokeToken;
    address public owner = address(this);
    address public alice = address(0x1);
    address public bob = address(0x2);
    address public charlie = address(0x3);

      function setUp() public {
        pokeToken = new PokeToken();
        pokemanNFT = new PokemanNFT(address(pokeToken));
        marketplace = new PokemanMarketplace(address(pokemanNFT), address(pokeToken));
    }

     function test_Deployment() public view {
        assertEq(address(marketplace.pokemanNFT()), address(pokemanNFT));
        assertEq(address(marketplace.pokeToken()), address(pokeToken));
    }

    function test_List_UserOwnedNFT() public {
        // Setup: Give alice an NFT
        uint256[] memory pokemanIds = new uint256[](1);
        pokemanIds[0] = 25;
        pokemanNFT.setAvailableForMint(pokemanIds);
        
        // Airdrop POKEs and stake
        address[] memory recipients = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        recipients[0] = alice;
        amounts[0] = 2e5;
        pokeToken.batchAirdrop(recipients, amounts);

        vm.prank(alice);
        pokeToken.approve(address(pokemanNFT), 1e5);
        
        vm.prank(alice);
        pokemanNFT.stake(1e5);

        vm.warp(block.timestamp + 1 hours);
        vm.prank(alice);
        pokemanNFT.mint(25);

        // Approve marketplace to transfer NFT
        vm.prank(alice);
        pokemanNFT.approve(address(marketplace), 25);

        // List the NFT
        vm.prank(alice);
        marketplace.list(25, 1e4); // 10,000 POKEs

        assertTrue(marketplace.isListed(25));
        (address seller, uint256 price) = marketplace.listings(25);
        assertEq(seller, alice);
        assertEq(price, 1e4);
        assertEq(pokemanNFT.ownerOf(25), address(marketplace));
    }

    function test_List_ContractHeldNFT() public {
        // Pre-mint NFT to contract
        uint256[] memory pokemanIds = new uint256[](1);
        pokemanIds[0] = 25;
        pokemanNFT.preMint(pokemanIds);

        // Approve marketplace to transfer from contract
        pokemanNFT.approveFromContract(address(marketplace), 25);


        // List the NFT (only owner can list contract-held NFTs)
        marketplace.list(25, 1e4);

        assertTrue(marketplace.isListed(25));
        
        (address seller, uint256 price) = marketplace.listings(25);
        assertEq(seller, address(this));
        assertEq(price, 1e4);
        assertEq(pokemanNFT.ownerOf(25), address(marketplace));
    }

      function test_List_NotOwner() public {
        // Try to list without owning the NFT
        vm.prank(alice);
        vm.expectRevert("ERC721NonexistentToken(25)");
        marketplace.list(25, 1e4);
    }

        function test_List_AlreadyListed() public {
        // Setup: Give alice an NFT and list it
        uint256[] memory pokemanIds = new uint256[](1);
        pokemanIds[0] = 25;
        pokemanNFT.setAvailableForMint(pokemanIds);
        
        address[] memory recipients = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        recipients[0] = alice;
        amounts[0] = 2e5;
        pokeToken.batchAirdrop(recipients, amounts);

        vm.prank(alice);
        pokeToken.approve(address(pokemanNFT), 1e5);
        
        vm.prank(alice);
        pokemanNFT.stake(1e5);

        vm.warp(block.timestamp + 1 hours);
        vm.prank(alice);
        pokemanNFT.mint(25);

        vm.prank(alice);
        pokemanNFT.approve(address(marketplace), 25);

        vm.prank(alice);
        marketplace.list(25, 1e4);

        // Try to list the same NFT again
        vm.prank(alice);
        vm.expectRevert("Already listed");
        marketplace.list(25, 2e4);
    }

      function test_List_ZeroPrice() public {
        // Setup: Give alice an NFT
        uint256[] memory pokemanIds = new uint256[](1);
        pokemanIds[0] = 25;
        pokemanNFT.setAvailableForMint(pokemanIds);
        
        address[] memory recipients = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        recipients[0] = alice;
        amounts[0] = 2e5;
        pokeToken.batchAirdrop(recipients, amounts);

        vm.prank(alice);
        pokeToken.approve(address(pokemanNFT), 1e5);
        
        vm.prank(alice);
        pokemanNFT.stake(1e5);

        vm.warp(block.timestamp + 1 hours);
        vm.prank(alice);
        pokemanNFT.mint(25);

        vm.prank(alice);
        pokemanNFT.approve(address(marketplace), 25);

        vm.prank(alice);
        vm.expectRevert("Price must be > 0");
        marketplace.list(25, 0);
    }
    function test_Buy() public {
        // Setup: List an NFT
        uint256[] memory pokemanIds = new uint256[](1);
        pokemanIds[0] = 25;
        pokemanNFT.setAvailableForMint(pokemanIds);
        
        address[] memory recipients = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        recipients[0] = alice;
        amounts[0] = 2e5;
        pokeToken.batchAirdrop(recipients, amounts);

        vm.prank(alice);
        pokeToken.approve(address(pokemanNFT), 1e5);
        
        vm.prank(alice);
        pokemanNFT.stake(1e5);

        vm.warp(block.timestamp + 1 hours);
        vm.prank(alice);
        pokemanNFT.mint(25);

        vm.prank(alice);
        pokemanNFT.approve(address(marketplace), 25);

        vm.prank(alice);
        marketplace.list(25, 1e4);

        // Airdrop POKEs to buyer
        address[] memory buyerRecipients = new address[](1);
        uint256[] memory buyerAmounts = new uint256[](1);
        buyerRecipients[0] = bob;
        buyerAmounts[0] = 2e4;
        pokeToken.batchAirdrop(buyerRecipients, buyerAmounts);

        // Buy the NFT
        vm.prank(bob);
        pokeToken.approve(address(marketplace), 1e4);
        
        vm.prank(bob);
        marketplace.buy(25);

        assertEq(pokemanNFT.ownerOf(25), bob);
        assertEq(pokeToken.balanceOf(alice), 11e4); // Seller received payment
        assertEq(pokeToken.balanceOf(bob), 1e4); // Buyer has remaining balance
        assertFalse(marketplace.isListed(25));
    }
 function test_Buy_NotListed() public {
        vm.prank(alice);
        vm.expectRevert("Not listed");
        marketplace.buy(25);
    }

     function test_Buy_OwnNFT() public {
        // Setup: List an NFT
        uint256[] memory pokemanIds = new uint256[](1);
        pokemanIds[0] = 25;
        pokemanNFT.setAvailableForMint(pokemanIds);
        
        address[] memory recipients = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        recipients[0] = alice;
        amounts[0] = 2e5;
        pokeToken.batchAirdrop(recipients, amounts);

        vm.prank(alice);
        pokeToken.approve(address(pokemanNFT), 1e5);
        
        vm.prank(alice);
        pokemanNFT.stake(1e5);

        vm.warp(block.timestamp + 1 hours);
        vm.prank(alice);
        pokemanNFT.mint(25);

        vm.prank(alice);
        pokemanNFT.approve(address(marketplace), 25);

        vm.prank(alice);
        marketplace.list(25, 1e4);

        // Try to buy own NFT
        vm.prank(alice);
        vm.expectRevert("Cannot buy your own NFT");
        marketplace.buy(25);
    }

    function test_Buy_InsufficientPOKEs() public {
        // Setup: List an NFT
        uint256[] memory pokemanIds = new uint256[](1);
        pokemanIds[0] = 25;
        pokemanNFT.setAvailableForMint(pokemanIds);
        
        address[] memory recipients = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        recipients[0] = alice;
        amounts[0] = 2e5;
        pokeToken.batchAirdrop(recipients, amounts);

        vm.prank(alice);
        pokeToken.approve(address(pokemanNFT), 1e5);
        
        vm.prank(alice);
        pokemanNFT.stake(1e5);

        vm.warp(block.timestamp + 1 hours);
        vm.prank(alice);
        pokemanNFT.mint(25);

        vm.prank(alice);
        pokemanNFT.approve(address(marketplace), 25);

        vm.prank(alice);
        marketplace.list(25, 1e4);

        // Try to buy without enough POKEs
        vm.prank(bob);
        vm.expectRevert();
        
        marketplace.buy(25);
    }

    function test_Cancel() public {
        // Setup: List an NFT
        uint256[] memory pokemanIds = new uint256[](1);
        pokemanIds[0] = 25;
        pokemanNFT.setAvailableForMint(pokemanIds);
        
        address[] memory recipients = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        recipients[0] = alice;
        amounts[0] = 2e5;
        pokeToken.batchAirdrop(recipients, amounts);

        vm.prank(alice);
        pokeToken.approve(address(pokemanNFT), 1e5);
        
        vm.prank(alice);
        pokemanNFT.stake(1e5);

        vm.warp(block.timestamp + 1 hours);
        vm.prank(alice);
        pokemanNFT.mint(25);

        vm.prank(alice);
        pokemanNFT.approve(address(marketplace), 25);

        vm.prank(alice);
        marketplace.list(25, 1e4);

        // Cancel the listing
        vm.prank(alice);
        marketplace.cancel(25);

        assertEq(pokemanNFT.ownerOf(25), alice);
        assertFalse(marketplace.isListed(25));
    }

     function test_Cancel_NotSeller() public {
        // Setup: List an NFT
        uint256[] memory pokemanIds = new uint256[](1);
        pokemanIds[0] = 25;
        pokemanNFT.setAvailableForMint(pokemanIds);
        
        address[] memory recipients = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        recipients[0] = alice;
        amounts[0] = 2e5;
        pokeToken.batchAirdrop(recipients, amounts);

        vm.prank(alice);
        pokeToken.approve(address(pokemanNFT), 1e5);
        
        vm.prank(alice);
        pokemanNFT.stake(1e5);

        vm.warp(block.timestamp + 1 hours);
        vm.prank(alice);
        pokemanNFT.mint(25);

        vm.prank(alice);
        pokemanNFT.approve(address(marketplace), 25);

        vm.prank(alice);
        marketplace.list(25, 1e4);

        // Try to cancel from different user
        vm.prank(bob);
        vm.expectRevert("Not seller");
        marketplace.cancel(25);
    }

    function test_IsListed() public {
        assertFalse(marketplace.isListed(25));

        // Setup: List an NFT
        uint256[] memory pokemanIds = new uint256[](1);
        pokemanIds[0] = 25;
        pokemanNFT.setAvailableForMint(pokemanIds);
        
        address[] memory recipients = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        recipients[0] = alice;
        amounts[0] = 2e5;
        pokeToken.batchAirdrop(recipients, amounts);

        vm.prank(alice);
        pokeToken.approve(address(pokemanNFT), 1e5);
        
        vm.prank(alice);
        pokemanNFT.stake(1e5);

        vm.warp(block.timestamp + 1 hours);
        vm.prank(alice);
        pokemanNFT.mint(25);

        vm.prank(alice);
        pokemanNFT.approve(address(marketplace), 25);

        vm.prank(alice);
        marketplace.list(25, 1e4);

        assertTrue(marketplace.isListed(25));
    }
}