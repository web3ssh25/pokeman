// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/PokemanMarketplace.sol";
import "../src/PokemanNFT.sol";

contract PokemanMarketplaceList is Script {
    function run() external {
        address marketplaceAddress = vm.envAddress("MARKETPLACE_ADDRESS");
        address pokemanNFTAddress = vm.envAddress("POKEMANNFT_ADDRESS");
        uint256 ownerKey = vm.envUint("DEPLOYER_PRIVATE_KEY"); // Contract owner
        uint256 user1Key = vm.envUint("USER1_PRIVATE_KEY"); // User1
        uint256 user2Key = vm.envUint("USER2_PRIVATE_KEY"); // User1

        PokemanMarketplace marketplace = PokemanMarketplace(marketplaceAddress);
        PokemanNFT pokemanNFT = PokemanNFT(pokemanNFTAddress);

        // --- List NFT owned by contract (IDs 1, 2, 3) ---
        uint256[] memory contractIds = new uint256[](3);
        contractIds[0] = 1;
        contractIds[1] = 2;
        contractIds[2] = 3;

        vm.startBroadcast(ownerKey);
        for (uint256 i = 0; i < contractIds.length; i++) {
            // Approve marketplace for each NFT (using helper if needed)
            pokemanNFT.approveFromContract(marketplaceAddress, contractIds[i]);
            // List on marketplace
            marketplace.list(contractIds[i], 1e4 + i * 1e4); // Prices: 10000, 20000, 30000 POKEs
            console.log("Listed contract-owned NFT ID:", contractIds[i]);
        }
        vm.stopBroadcast();

        // --- List NFT owned by user (IDs 4, 5) ---
        uint256[] memory userIds = new uint256[](2);
        userIds[0] = 4;
        userIds[1] = 5;

        vm.startBroadcast(user1Key);       
        pokemanNFT.approve(marketplaceAddress, userIds[0]);
        marketplace.list(userIds[0], 5e4); 
        console.log("Listed user-owned NFT ID:", userIds[0]);   
        vm.stopBroadcast();

        vm.startBroadcast(user2Key);       
        pokemanNFT.approve(marketplaceAddress, userIds[1]);
        marketplace.list(userIds[1], 5e4); 
        console.log("Listed user-owned NFT ID:", userIds[1]);   
        vm.stopBroadcast();
    }
}