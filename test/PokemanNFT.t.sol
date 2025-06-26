// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/PokemanNFT.sol";
import "../src/PokeToken.sol";

contract PokemanNFTTest is Test {
    PokemanNFT public pokemanNFT;
    PokeToken public pokeToken;
    address public owner = address(this);
    address public alice = address(0x1);
    address public bob = address(0x2);
    address public charlie = address(0x3);

    function setUp() public {
        pokeToken = new PokeToken();
        pokemanNFT = new PokemanNFT(address(pokeToken));
    }

  function test_Deployment() public view {
        assertEq(pokemanNFT.name(), "PokemanNFT");
        assertEq(pokemanNFT.symbol(), "PMN");
        assertEq(pokemanNFT.owner(), owner);
        assertEq(address(pokemanNFT.pokeToken()), address(pokeToken));
        assertEq(pokemanNFT.requiredStake(), 1 ether);
        assertEq(pokemanNFT.coolingPeriod(), 10 minutes);
    }

    function test_PreMint() public {
        uint256[] memory pokemanIds = new uint256[](2);
        pokemanIds[0] = 1;
        pokemanIds[1] = 2;

        pokemanNFT.preMint(pokemanIds);

        uint256[] memory validIDs = pokemanNFT.getAllValidIDs();

        assertEq(validIDs[0],1);
        assertEq(validIDs[1],2);

        assertEq(pokemanNFT.ownerOf(1), address(pokemanNFT));
        assertEq(pokemanNFT.ownerOf(2), address(pokemanNFT));
        assertTrue(pokemanNFT.minted(1));
        assertTrue(pokemanNFT.minted(2));
    }

      function test_PreMint_AlreadyMinted() public {
        uint256[] memory pokemanIds = new uint256[](1);
        pokemanIds[0] = 1;

        pokemanNFT.preMint(pokemanIds);

        vm.expectRevert("PokemanNFT: already minted");
        pokemanNFT.preMint(pokemanIds);
    }
        function test_PreMint_NotOwner() public {
        uint256[] memory pokemanIds = new uint256[](1);
        pokemanIds[0] = 1;

        vm.prank(alice);
        vm.expectRevert("OwnableUnauthorizedAccount(0x0000000000000000000000000000000000000001)");
        pokemanNFT.preMint(pokemanIds);
    }

      function test_SetAvailableForMint() public {
        uint256[] memory pokemanIds = new uint256[](2);
        pokemanIds[0] = 10;
        pokemanIds[1] = 20;

        pokemanNFT.setAvailableForMint(pokemanIds);

        assertTrue(pokemanNFT.availableForMint(10));
        assertTrue(pokemanNFT.availableForMint(20));
    }

     function test_SetAvailableForMint_NotOwner() public {
        uint256[] memory pokemanIds = new uint256[](1);
        pokemanIds[0] = 10;

        vm.prank(alice);
        vm.expectRevert("OwnableUnauthorizedAccount(0x0000000000000000000000000000000000000001)");
        pokemanNFT.setAvailableForMint(pokemanIds);
    }

     function test_Stake() public {
        // First airdrop POKEs to alice
        address[] memory recipients = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        recipients[0] = alice;
        amounts[0] = 10 ether; 
        pokeToken.batchAirdrop(recipients, amounts);

        vm.prank(alice);
        pokeToken.approve(address(pokemanNFT), 1 ether);
        
        vm.prank(alice);
        pokemanNFT.stake(1 ether);

        assertEq(pokemanNFT.stakedAmount(alice), 1 ether);
        assertEq(pokeToken.balanceOf(address(pokemanNFT)), 1 ether);
    }

     function test_Stake_InsufficientAmount() public {
        vm.prank(alice);
        vm.expectRevert("PokemanNFT: stake at least required amount");
        pokemanNFT.stake(100000 wei); // 50,000 POKEs (less than required 100,000)
    }
       function test_Stake_AlreadyStaked() public {
        // First airdrop and stake
        address[] memory recipients = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        recipients[0] = alice;
        amounts[0] = 10 ether;
        pokeToken.batchAirdrop(recipients, amounts);

        vm.prank(alice);
        pokeToken.approve(address(pokemanNFT), 2 ether);
        
        vm.prank(alice);
        pokemanNFT.stake(1 ether);

        // Try to stake again
        vm.prank(alice);
        vm.expectRevert("PokemanNFT: already staked");
        pokemanNFT.stake(1 ether);
    }

    function test_Mint() public {
        // Setup: airdrop POKEs, stake, and set availability
        address[] memory recipients = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        recipients[0] = alice;
        amounts[0] = 10 ether;
        pokeToken.batchAirdrop(recipients, amounts);

        vm.prank(alice);
        pokeToken.approve(address(pokemanNFT), 2 ether);
        
        vm.prank(alice);
        pokemanNFT.stake(1 ether);

        uint256[] memory pokemanIds = new uint256[](1);
        pokemanIds[0] = 25;
        pokemanNFT.setAvailableForMint(pokemanIds);

        vm.warp(block.timestamp + 20 minutes);
        vm.prank(alice);
        pokemanNFT.mint(25);

        assertEq(pokemanNFT.ownerOf(25), alice);
        assertTrue(pokemanNFT.minted(25));
        assertEq(pokemanNFT.lastMintTime(alice), block.timestamp);
    }

    
    function test_Mint_NotAvailable() public {
        // Setup staking but don't set availability
        address[] memory recipients = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        recipients[0] = alice;
        amounts[0] = 10 ether;
        pokeToken.batchAirdrop(recipients, amounts);

        vm.prank(alice);
        pokeToken.approve(address(pokemanNFT), 1 ether);
        
        vm.prank(alice);
        pokemanNFT.stake(1 ether);

        vm.prank(alice);
        vm.expectRevert("PokemanNFT: not available for minting");
        pokemanNFT.mint(25);
    }
      function test_Mint_NotStaked() public {
        uint256[] memory pokemanIds = new uint256[](1);
        pokemanIds[0] = 25;
        pokemanNFT.setAvailableForMint(pokemanIds);

        vm.prank(alice);
        vm.expectRevert("PokemanNFT: not enough staked");
        pokemanNFT.mint(25);
    }
        function test_Mint_CoolingPeriod() public {
        // Setup: stake and set availability
        address[] memory recipients = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        recipients[0] = alice;
        amounts[0] = 10 ether;
        pokeToken.batchAirdrop(recipients, amounts);

        vm.prank(alice);
        pokeToken.approve(address(pokemanNFT), 1 ether);
        
        vm.prank(alice);
        pokemanNFT.stake(1 ether);

        uint256[] memory pokemanIds = new uint256[](2);
        pokemanIds[0] = 25;
        pokemanIds[1] = 26;
        pokemanNFT.setAvailableForMint(pokemanIds);

        // First mint
        vm.warp(block.timestamp + 10 minutes);
        vm.prank(alice);
        pokemanNFT.mint(25);

        // Try to mint again immediately (should fail)
        vm.prank(alice);
        vm.expectRevert("PokemanNFT: cooling period not over");
        pokemanNFT.mint(26);

        // Wait for cooling period and try again
        vm.warp(block.timestamp + 10 minutes);
        
        vm.prank(alice);
        pokemanNFT.mint(26);

        assertEq(pokemanNFT.ownerOf(25), alice);
        assertEq(pokemanNFT.ownerOf(26), alice);
    }
    function test_Unstake() public {
        // Setup: stake and mint
        address[] memory recipients = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        recipients[0] = alice;
        amounts[0] = 10 ether;
        pokeToken.batchAirdrop(recipients, amounts);

        vm.prank(alice);
        pokeToken.approve(address(pokemanNFT), 1 ether);
        
        vm.prank(alice);
        pokemanNFT.stake(1 ether);

        uint256[] memory pokemanIds = new uint256[](1);
        pokemanIds[0] = 25;
        pokemanNFT.setAvailableForMint(pokemanIds);

        vm.warp(block.timestamp + 10 minutes);
        vm.prank(alice);
        pokemanNFT.mint(25);

        // Try to unstake immediately (should fail)
        vm.prank(alice);
        vm.expectRevert("PokemanNFT: cooling period not over");
        pokemanNFT.unstake();

        // Wait for cooling period and unstake
        vm.warp(block.timestamp + 10 minutes);
        
        vm.prank(alice);
        pokemanNFT.unstake();

        assertEq(pokemanNFT.stakedAmount(alice), 0);
        assertEq(pokeToken.balanceOf(alice), 10 ether); // Original 2e5 - staked 1e5 + returned 1e5
    }

     function test_Unstake_NotStaked() public {
        vm.prank(alice);
        vm.expectRevert("PokemanNFT: nothing to unstake");
        pokemanNFT.unstake();
    }

    function test_TokenURI() public {
        // Pre-mint a token
        uint256[] memory pokemanIds = new uint256[](1);
        pokemanIds[0] = 25;
        pokemanNFT.preMint(pokemanIds);

        string memory uri = pokemanNFT.tokenURI(25);
        assertEq(uri, "https://pokeapi.co/api/v2/pokemon/25");
    }

    function test_TokenURI_NonexistentToken() public {
        vm.expectRevert("PokemanNFT: URI query for nonexistent token");
        pokemanNFT.tokenURI(999);
    }

    function test_SetRequiredStake() public {
        pokemanNFT.setRequiredStake(2 ether);
        assertEq(pokemanNFT.requiredStake(), 2 ether);
    }

    function test_SetCoolingPeriod() public {
        pokemanNFT.setCoolingPeriod(20 minutes);
        assertEq(pokemanNFT.coolingPeriod(), 20 minutes);
    }
}