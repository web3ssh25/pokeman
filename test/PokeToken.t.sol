// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/PokeToken.sol";

contract PokeTokenTest is Test {
 PokeToken public pokeToken;
 address public owner = address(this);
 address public alice = address(0x1);
 address public bob = address(0x2);
 address public charlie = address(0x3);

 function setUp() public {
    pokeToken = new PokeToken();
 }

 function test_Deployment() public view {
    assertEq(pokeToken.name(), "Pokes");
    assertEq(pokeToken.symbol(), "POKE");
    assertEq(pokeToken.decimals(), 18);
    assertEq(pokeToken.totalSupply(), 1e18 ether);
    assertEq(pokeToken.balanceOf(address(pokeToken)), 1e18 ether);
    assertEq(pokeToken.balanceOf(alice), 0);
    assertEq(pokeToken.balanceOf(bob), 0);
    assertEq(pokeToken.balanceOf(charlie), 0);
    assertEq(pokeToken.owner(), owner);
 }

 function test_BatchAirdrop() public {
    address[] memory recipients = new address[](3);
    recipients[0] = alice;
    recipients[1] = bob;
    recipients[2] = charlie;

    uint256[] memory amounts = new uint256[](3);
    amounts[0] = 100 ether; 
    amounts[1] = 200 ether; 

    pokeToken.batchAirdrop(recipients, amounts);
     assertEq(pokeToken.balanceOf(alice), 100 ether);
     assertEq(pokeToken.balanceOf(bob), 200 ether);
     assertEq(pokeToken.balanceOf(address(pokeToken)), (1e18 ether - 300 ether));
 }

  function test_BatchAirdrop_ExceedsMaxAddresses() public {
        address[] memory recipients = new address[](11);
        uint256[] memory amounts = new uint256[](11);
        
        for (uint256 i = 0; i < 11; i++) {
            recipients[i] = address(uint160(i + 1));
            amounts[i] = 100 ether;
        }

        vm.expectRevert("PokeToken: invalid number of recipients");
        pokeToken.batchAirdrop(recipients, amounts);
    }
     function test_BatchAirdrop_LengthMismatch() public {
        address[] memory recipients = new address[](2);
        uint256[] memory amounts = new uint256[](3);
        
        recipients[0] = alice;
        recipients[1] = bob;
        amounts[0] = 100 ether;
        amounts[1] = 200 ether;
        amounts[2] = 300 ether;

        vm.expectRevert("PokeToken: recipients and amounts length mismatch");
        pokeToken.batchAirdrop(recipients, amounts);
    }
     function test_BatchAirdrop_InsufficientBalance() public {
        address[] memory recipients = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        
        recipients[0] = alice;
        amounts[0] = 2e18 ether; // More than total supply

        vm.expectRevert("PokeToken: insufficient contract balance");
        pokeToken.batchAirdrop(recipients, amounts);
    }
      function test_BatchAirdrop_NotOwner() public {
        address[] memory recipients = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        
        recipients[0] = alice;
        amounts[0] = 1e17 ether;

        vm.prank(alice);
        vm.expectRevert("OwnableUnauthorizedAccount(0x0000000000000000000000000000000000000001)");
        pokeToken.batchAirdrop(recipients, amounts);
    }
      function test_BatchAirdrop_EmptyArray() public {
        address[] memory recipients = new address[](0);
        uint256[] memory amounts = new uint256[](0);

        vm.expectRevert("PokeToken: invalid number of recipients");
        pokeToken.batchAirdrop(recipients, amounts);
    }

     function test_Transfer() public {
        // First airdrop some tokens
        address[] memory recipients = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        recipients[0] = alice;
        amounts[0] = 100 ether;
        pokeToken.batchAirdrop(recipients, amounts);

        // Test transfer
        vm.prank(alice);
        pokeToken.transfer(bob, 50 ether);
        
        assertEq(pokeToken.balanceOf(alice), 50 ether);
        assertEq(pokeToken.balanceOf(bob), 50 ether);
    }
     function test_TransferFrom() public {
        // First airdrop some tokens
        address[] memory recipients = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        recipients[0] = alice;
        amounts[0] = 100 ether;
        pokeToken.batchAirdrop(recipients, amounts);

        // Approve and transferFrom
        vm.prank(alice);
        pokeToken.approve(bob, 50 ether);
        
        vm.prank(bob);
        pokeToken.transferFrom(alice, charlie, 50 ether);
        
        assertEq(pokeToken.balanceOf(alice), 50 ether);
        assertEq(pokeToken.balanceOf(charlie), 50 ether);
    }
}