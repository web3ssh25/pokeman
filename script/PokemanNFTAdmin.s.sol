// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/PokemanNFT.sol";

contract PokemanNFTAdmin is Script {
    function run() external {
        // Read the PokemanNFT address from env
        address pokemanNFTAddress = vm.envAddress("POKEMANNFT_ADDRESS");
        PokemanNFT pokemanNFT = PokemanNFT(pokemanNFTAddress);

        // Log the contract and owner
        console.log("Interacting with PokemanNFT at:", pokemanNFTAddress);
        console.log("Current owner is:", pokemanNFT.owner());

        // Example: Pre-mint Pokeman IDs 1, 2, 3 to the contract
        uint256[] memory premintIds = new uint256[](3);
        premintIds[0] = 1;
        premintIds[1] = 2;
        premintIds[2] = 3;

        // Example: Set Pokeman IDs 4, 5, 6 as available for user minting
        uint256[] memory availableIds = new uint256[](3);
        availableIds[0] = 4;
        availableIds[1] = 5;
        availableIds[2] = 6;

        // Start broadcasting as the contract owner
        uint256 privateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        // Pre-mint NFTs to the contract
        pokemanNFT.preMint(premintIds);

        // Set available IDs for user minting
        pokemanNFT.setAvailableForMint(availableIds);

        // (Optional) Transfer ownership to a new address
        // address newOwner = vm.envAddress("NEW_OWNER_ADDRESS");
        // pokemanNFT.transferOwnership(newOwner);

        vm.stopBroadcast();

        console.log("Pre-minted IDs: 1, 2, 3");
        console.log("Set available for minting: 4, 5, 6");
    }
}